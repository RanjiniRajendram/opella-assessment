# CI/CD Pipeline

This repository uses a GitHub Actions workflow at `.github/workflows/deploy.yml` to validate, test, document, plan and (optionally) apply Terraform changes for multiple environments.

Summary of the pipeline behavior
- Triggers: `push` to `main` (deploy on main) and `pull_request` for validation.
- Jobs:
	- `validate` — formatting and `terraform validate` across environments and modules (runs on PRs).
	- `test` — runs native Terraform module tests (`terraform test -verbose`) and checks `terraform-docs` output (runs on PRs).
	- `plan` — runs `terraform plan` for `dev`, `qa`, and `prod` (runs on PRs to show changes).
	- `deploy` — runs on push to `main` and auto-applies for `dev` and `qa` (creates `tfplan` and runs `terraform apply -auto-approve`).
	- `deploy-prod` — production deploy which runs plan on `main` and requires a manual approval via the GitHub environment (no auto-apply without approval).

Key notes and requirements
- The workflow uses `hashicorp/setup-terraform` and requires Terraform 1.6+ (set via `TERRAFORM_VERSION`).
- Azure authentication is performed with `azure/login` and requires the following repository secrets: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID`.
- Remote state backend is the Azure Storage account defined by workflow env vars (`AZURE_BACKEND_RG`, `AZURE_BACKEND_ACCOUNT`, `AZURE_BACKEND_CONTAINER`). Ensure the storage account and container exist before applying.
- Documentation enforcement: `terraform-docs` is installed during CI and the build will fail if module README docs are out-of-sync.

Recommendations for using the pipeline
- Protect the `main` branch and require pull requests with passing checks before merge.
- Configure GitHub environment protection rules for `prod` to require explicit reviewers/approvals.
- Store least-privilege credentials in GitHub Secrets and prefer a dedicated service principal per environment or CI principal with scoped RBAC.

See the workflow file: [.github/workflows/deploy.yml](.github/workflows/deploy.yml)


