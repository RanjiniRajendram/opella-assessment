# GitHub Actions Pipeline Documentation

## Overview

This GitHub Actions pipeline implements a professional, multi-environment Terraform deployment strategy with the following characteristics:

- **PR Validation**: Lint, format check, and validation without Azure login or infrastructure changes
- **Module Testing**: Native Terraform tests on pull requests
- **Documentation Validation**: Ensures terraform-docs are current on PRs  
- **Non-Prod Deployment**: Automatic deployment of dev and qa on push to main using matrix strategy
- **Production Deployment**: Separate job with manual approval requirement
- **Artifact Management**: Plan and output artifacts stored for audit and reference

---

## Pipeline Stages

### 1. Validate (PR Only)
- **Trigger**: Pull requests
- **Steps**:
  - Terraform format check (`terraform fmt -check`)
  - Terraform syntax validation (`terraform validate`)
  - No Azure login required
  - No infrastructure changes
- **Purpose**: Fast, local validation on every PR

### 2. Test Module (PR Only)
- **Trigger**: Pull requests (depends on validate)
- **Steps**:
  - Azure login (for test environment provisioning)
  - Run native Terraform tests with `terraform test -verbose`
  - Tests are located in `terraform/modules/vnet/tests/`
- **Purpose**: Ensure module functionality before merge

### 3. Documentation (PR Only)
- **Trigger**: Pull requests (depends on validate)
- **Steps**:
  - Install terraform-docs
  - Check with `--output-mode=check` (fails if docs are stale)
- **Purpose**: Enforce documentation as definition of done

### 4. Plan (PR Only)
- **Trigger**: Pull requests (depends on validate)
- **Strategy**: Matrix for dev, qa, prod
- **Steps**:
  - Azure login
  - `terraform init` with partial backend config
  - `terraform plan` (no apply)
  - Upload plan artifact for review
- **Purpose**: Show what would change without applying

### 5. Deploy Non-Prod (Push to Main Only)
- **Trigger**: Push to main branch
- **Strategy**: Matrix for dev, qa
- **Environment Protection**: Yes (via GitHub Environments)
- **Steps**:
  - Depends on all PR checks (validate, test-module, docs, plan)
  - Azure login
  - `terraform init` with full backend config
  - `terraform plan`
  - `terraform apply -auto-approve`
  - Output terraform outputs to artifact
- **Purpose**: Automatically deploy dev and qa after PR merge

### 6. Deploy Production (Push to Main Only)
- **Trigger**: Push to main branch
- **Environment Protection**: Yes (requires manual approval)
- **Steps**:
  - Depends on deploy-nonprod success
  - Azure login
  - `terraform init` with full backend config
  - `terraform plan`
  - `terraform apply -auto-approve`
  - Output terraform outputs to artifact
- **Purpose**: Controlled production deployment with explicit approval gate

---

## Environment Configuration

### GitHub Environments Setup

To enable the approval gates and environment-specific protection rules:

1. **For dev environment:**
   - Go to repo → Settings → Environments → Create environment "dev"
   - (Optional) Add deployment branches restriction to "main"
   - No approval required (automatic deployment)

2. **For qa environment:**
   - Go to repo → Settings → Environments → Create environment "qa"
   - (Optional) Add deployment branches restriction to "main"
   - (Optional) Add required reviewers if gates needed

3. **For prod environment:**
   - Go to repo → Settings → Environments → Create environment "prod"
   - **Check**: "Required reviewers"
   - Add team leads or DevOps engineers as required reviewers
   - Add deployment branches restriction to "main"
   - (Optional) Add environment secrets if different from repo secrets

### Backend Configuration

Each environment uses partial backend configuration via command-line flags:

```hcl
terraform init \
  -backend-config="resource_group_name=tfstate-rg" \
  -backend-config="storage_account_name=tfstate_gep_assessment" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=<ENVIRONMENT>.tfstate" \
  -input=false
```

- `dev.tfstate` – Development state file
- `qa.tfstate` – QA state file
- `prod.tfstate` – Production state file

Each environment's `.tfvars` file specifies the appropriate region and resources.

### Azure Service Principal Secrets

Configure these in repo Settings → Secrets → Actions:

- `AZURE_CLIENT_ID` – Service principal client ID
- `AZURE_TENANT_ID` – Azure tenant ID
- `AZURE_SUBSCRIPTION_ID` – Azure subscription ID

These are automatically injected into `azure/login@v1` actions.

---

## Workflow Behavior

### On Pull Request

1. **validate** job runs:
   - Format check for all Terraform
   - Validation for all environments and modules
   - No Azure login

2. If validate passes:
   - **test-module** runs (for vnet module)
   - **docs** runs (for documentation check)
   - **plan** runs (matrix for all 3 envs, shows changes without applying)

3. PR author reviews:
   - Plan output
   - Test results
   - Documentation updates

### On Push to Main

1. **validate** job runs (must pass from PR)

2. If validate + tests + docs pass:
   - **deploy-nonprod** matrix job runs for dev and qa
   - Each environment auto-deploys (no approval needed)

3. If deploy-nonprod succeeds:
   - **deploy-prod** waits for approval
   - Requires GitHub Environment "prod" with reviewers configured
   - Reviewer must approve in Actions tab; then prod deploys

---

## Matrix Strategy Benefits

The matrix approach for dev, qa, and prod (on plan) allows:

- Parallel validation of all environments
- Consistent steps across environments
- Easy to add/remove environments by updating the matrix
- Clear visibility into which environment failed

Example:
```yaml
strategy:
  matrix:
    environment: [dev, qa, prod]
```

---

## Artifact Management

- **tfplan files**: Uploaded during plan stage, 5-day retention
- **outputs.json**: Uploaded after apply, 30-day retention (for audit/reference)

Download artifacts from Actions run for:
- Plan review on PR
- Outputs comparison after deployment
- Audit/compliance trails

---

## Best Practices Demonstrated

✅ **Separation of Concerns**: Validation, testing, planning, and deployment are separate jobs  
✅ **No Azure Login on Validate**: Fast PR validation without cloud access  
✅ **Matrix for Code Reuse**: dev/qa use same steps, easy scaling  
✅ **Approval Gate for Prod**: Manual confirmation before production changes  
✅ **Artifact Retention**: Plans and outputs retained for audit  
✅ **Pinned Terraform Version**: Consistency across CI and local development  
✅ **Partial Backend Config**: Dynamic environment-specific keys per deployment  
✅ **Native Tests**: module tests run early in pipeline  
✅ **Doc Validation**: Documentation checked before merge  

---

## Running Locally

Mirror the pipeline locally with:

```bash
# Install pre-commit
pip install pre-commit
pre-commit install

# Validate (no Azure login needed)
terraform fmt -check -recursive terraform/
terraform -chdir=terraform/environments/dev validate

# Run module tests (requires Azure login)
az login
cd terraform/modules/vnet && terraform test -verbose

# Plan dev
cd terraform/environments/dev
terraform init -backend-config="key=dev.tfstate" ...
terraform plan
```

---

## Troubleshooting

**Plan shows more changes than expected:**
- Check if local state is stale; pull latest from main

**Azure login fails in CI:**
- Verify AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID are configured in repo secrets
- Ensure service principal has adequate RBAC permissions

**Prod approval not showing:**
- Go to repo Settings → Environments → prod
- Verify "Required reviewers" is checked
- Ensure reviewers have repo access

**Backend key conflict:**
- Each environment must have unique `key` parameter
- Verify dev.tfstate, qa.tfstate, prod.tfstate are used correctly

---

## Future Enhancements

- Slack notifications on deploy success/fail
- Cost estimation via terraform-cost-estimation
- Policy as Code (Sentinel) checks before apply
- Blue/green or canary deployments for prod
- Automated rollback detection
