# Azure Infrastructure as Code Challenge

A professional, multi-environment Terraform setup for provisioning Azure infrastructure. This repository demonstrates Infrastructure as Code best practices using a reusable VNET module, environment-specific configurations, automated testing, and documentation.

## 📂 Repository Structure

```
.
├── terraform/
│   ├── backend_storage/          # Backend state configuration
│   ├── environments/
│   │   ├── dev/                  # Development environment (eastus)
│   │   └── prod/                 # Production environment (westus)
│   ├── modules/
│   │   └── vnet/                 # Reusable Azure VNET module (with tests)
│   └── policy/                   # Azure Policy definitions & assignments
├── pipeline/
│   └── .github/workflows/
│       └── deploy.yml            # Multi-job CI/CD pipeline
├── .pre-commit-config.yaml       # Pre-commit hooks (fmt, validate, docs)
├── .terraform-docs.yml           # terraform-docs configuration
└── README.md                      # This file
```

## 🏗️ Architecture

- **`modules/vnet`** – A reusable, tested Terraform module that creates:
  - Azure Virtual Network with configurable address space
  - Multiple subnets (driven by a map variable)
  - Network Security Group with subnet associations
  - Exposes outputs for integration (vnet_id, subnet_ids, nsg_id)

- **`environments/dev` and `environments/prod`** – Environment-specific configurations that:
  - Call the VNET module with environment-specific settings
  - Add a storage account and storage container (additional resource)
  - Add a Linux VM with NIC attached to the VNET subnet
  - Use resource group per environment with consistent tagging
  - Store Terraform state in Azure Storage with different keys per environment

- **`policy`** – Azure Policy definitions to enforce tagging standards (e.g., inherit `environment` and `region` tags from the resource group).

## � Committing your work

Before you push your changes, run the pre‑commit hooks to format, validate and regenerate documentation.  Then commit everything and open a pull request:

```bash
git add .
pre-commit run --all-files
git commit -m "chore: finalize infrastructure for challenge"
git push origin <your-branch>
```

Once the PR is merged to `main` the CI pipeline will deploy dev/qa automatically; production requires manual approval.

## �🚀 Quick Start

### Prerequisites
- Terraform 1.6+
- Azure CLI, authenticated (`az login`)
- Pre-commit (optional, for local hooks)

### Local Development

1. **Install pre-commit hooks:**
   ```bash
   pip install pre-commit
   pre-commit install
   ```

2. **Plan a deployment (dev):**
   ```bash
   cd terraform/environments/dev
   terraform init
   terraform plan
   ```

3. **Run module tests:**
   ```bash
   cd terraform/modules/vnet
   terraform test -verbose
   ```

4. **Generate/update documentation:**
   ```bash
   # Automatic via pre-commit (on `git commit`)
   # Or manually:
   terraform-docs markdown table --output-file README.md --output-mode=inject modules/vnet
   ```

### CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/deploy.yml`) runs:

1. **`terraform` job** – Validates and plans dev environment
   - Checks Terraform formatting
   - Validates HCL syntax
   - Runs `terraform fmt -check` and `terraform validate`
   - Plans and uploads the plan artifact
   - Auto-applies on push to `main`

2. **`terraform-prod` job** – Validates prod environment (plan only, no auto-apply for safety)
   - Depends on the dev job passing
   - Ensures prod configuration is always valid

3. **`module-test` job** – Runs native Terraform tests
   - Uses `terraform test -verbose` to validate the VNET module
   - Runs multiple test scenarios (single subnet, multi-subnet, various regions)

4. **`docs` job** – Validates documentation is up-to-date
   - Installs `terraform-docs`
   - Fails the build if module README is outdated
   - Enforces documentation as part of the definition of done

## 📚 Documentation Automation

We use `terraform-docs` to automatically generate and inject input/output documentation into `README.md` files.

**Why?**
- Eliminates manual copy–paste and documentation drift
- Keeps docs in sync with code changes
- Improves clarity for module consumers

**How it works:**
1. Pre-commit hook runs `terraform-docs` before every commit, auto-updating README sections between `<!-- BEGIN_TF_DOCS -->` and `<!-- END_TF_DOCS -->` markers.
2. CI validation ensures the documentation stays current; the build fails if docs are out of sync.
3. Developers are forced to commit up-to-date documentation alongside code changes.

See `terraform/modules/vnet/README.md` for an example.

## 🧪 Testing

The repository includes **native Terraform tests** (Terraform 1.6+) for the VNET module:

```bash
cd terraform/modules/vnet
terraform test -verbose
```

Tests validate:
- Module outputs are exported correctly (`vnet_id`, `subnet_ids`, `nsg_id`)
- Single and multiple subnet configurations work
- Various address spaces and regions are accepted
- Minimal configuration validates correctly

See `terraform/modules/vnet/tests/` for test definitions.
## 📄 capturing plan output

To share a plan with reviewers (or include in your submission), run a local plan and redirect it to a text file:

```bash
cd terraform/environments/dev          # or qa/prod
terraform init -backend=false          # avoids remote state
terraform plan -out=env.tfplan > ../env-plan.txt
```

The plain‑text `env-plan.txt` is human readable; the binary `env.tfplan` can be uploaded as a CI artifact. A sample placeholder is included at `terraform/environments/dev/plan-sample.txt`.
## 🔒 State & Backend

Terraform state is stored remotely in Azure Storage Account:

- **Resource Group:** `tfstate-rg`
- **Storage Account:** `tfstate_gep_assessment`
- **Container:** `tfstate`
- **State files:**
  - `dev.terraform.tfstate` – development environment state
  - `prod.terraform.tfstate` – production environment state

Each environment uses a separate state file via the `key` backend configuration.

## 🏷️ Tagging & Naming

All resources follow a consistent naming and tagging strategy:

**Naming:**
```
{environment}-{location}-{resource_type}
Example: dev-eastus-vnet, prod-westus-vm
```

**Tags:**
```hcl
{
  environment = "dev" or "prod"
  region      = "eastus" or "westus"
  project     = "gep-opella"
}
```

**Enforcement:**
Azure Policies (in `terraform/policy/`) automatically inherit tags from the resource group to child resources.

## ✅ Challenge Requirements Met

✅ **Reusable Module Creation**
- `modules/vnet` is fully parameterized and tested
- Flexible subnet configuration via map variable
- Includes NSG with subnet associations
- Auto-generated documentation via terraform-docs

✅ **Infrastructure Setup**
- Two environments (dev/prod) with separate states and regions
- VNET module + additional resources (storage, VM, network interface)
- Consistent naming and tagging across resources
- Resource group per environment

✅ **GitHub Pipeline**
- Multi-job workflow with dev/prod validation
- Module testing with native Terraform tests
- Documentation validation
- Plan artifact upload and optional auto-apply to main

✅ **Code Quality & Documentation**
- Pre-commit hooks for formatting, validation, and doc generation
- terraform-docs automation
- Terraform native tests (Terraform 1.6+)
- Policy-as-code for tagging enforcement

## 📝 Next Steps

1. **Set up Azure resources:**
   - Create the state storage account and container (see `terraform/backend_storage/`)
   - Ensure Azure service principal credentials are available (for CLI and CI)

2. **Configure GitHub Secrets:**
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`

3. **Push to main:**
   - Terraform will plan and apply dev environment
   - Prod is validated but requires manual apply for safety

4. **Review pipeline artifacts:**
   - Download the tfplan from the GitHub Actions run to review the plan

## 📖 Resources

- [Terraform Docs](https://www.terraform.io/docs)
- [terraform-docs](https://terraform-docs.io/)
- [Azure Terraform Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Testing](https://developer.hashicorp.com/terraform/language/tests)

---

**Contact:** For questions about this infrastructure, refer to the module and environment README files for detailed input/output documentation.
