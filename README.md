# aws-infrastructure — Terraform + AWS setup

This repository contains Terraform configuration to provision a small web stack for `gillzhub.com` (ALB, EC2 Windows IIS, Route53, ACM certificates, and optional GitHub Actions OIDC setup).

This README is written for contributors who may be unfamiliar with Terraform or AWS CLI. It explains how to prepare your local environment, initialize Terraform, and deploy safely.

## Quick checklist (high level)

- Install Terraform (v1.X+ recommended)
- Install AWS CLI and configure an AWS profile
- Copy `.envrc.example` to `.envrc` and set your AWS_PROFILE (or export env vars manually)
- Run `terraform init`, `terraform plan`, and `terraform apply` as needed

## Prerequisites

- macOS / Linux / Windows with a shell
- An AWS account with appropriate permissions (create roles, S3 buckets for backend, Route53 access, etc.)
- Terraform installed: https://developer.hashicorp.com/terraform
- AWS CLI installed and configured: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

## Repository layout (important files)

- `provider.tf` — Terraform backend and provider configuration (S3 backend + provider blocks)
- `main.tf`, `lb.tf`, `security.tf`, `certificates.tf`, `oidc.tf` — infrastructure resources
- `variables.tf`, `outputs.tf` — variables and outputs
- `oidc.tf` — OIDC provider & IAM role for GitHub Actions
- `.envrc.example` — example local environment file (do NOT commit your real `.envrc`)
- `.gitignore` — excludes local Terraform files and secrets
- `.github/workflows/deploy.yml` — example GitHub Actions workflow for deployments

## Local environment setup

1. Copy the example local env file (we use direnv or simple export) — replace placeholder values:

```bash
cp .envrc.example .envrc
# edit .envrc and set AWS_PROFILE to your local profile (e.g. zach-dev)
# or export directly in your shell
export AWS_PROFILE=your-profile-name
export AWS_REGION=us-west-2
```

If you use direnv, allow the file after creating it:

```bash
direnv allow
```

If you don't use `.envrc`, make sure at minimum to have `AWS_PROFILE` and/or `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` in your environment.

## AWS CLI configuration

If you haven't configured an AWS profile yet, run:

```bash
aws configure --profile your-profile-name
```

This will prompt for:
- AWS Access Key ID
- AWS Secret Access Key
- Default region name (e.g. us-west-2)
- Default output format (json)

Notes:
- Prefer using named profiles (AWS_PROFILE) rather than hardcoding keys or committing them
- For CI (GitHub Actions) we use OIDC so no long-lived secrets are necessary in GitHub

## Terraform initialization and provider notes

1. Install required providers and initialize the workspace:

```bash
terraform init
```

2. If you added the TLS data source (used to fetch the GitHub OIDC certificate thumbprint), ensure the TLS provider is declared in `provider.tf`. If you see an error complaining about the TLS provider, run `terraform init` to fetch it.

3. Run a plan to validate changes:

```bash
terraform plan -var-file="terraform.tfvars"  # if you use a tfvars file
```

4. Apply when ready:

```bash
terraform apply
```

### Common gotchas

- If you see provider mismatch errors after pulling changes, run `terraform init -upgrade` to reconcile provider versions.
- If you change provider blocks, sometimes you must reinitialize or remove `.terraform` locally before init.

## Variables and sensitive data

- Do NOT commit secrets such as `*.tfvars` files with credentials. These are ignored by `.gitignore`.
- Use variable definitions in `variables.tf` and pass values via CLI or a local-only `terraform.tfvars` that is not committed.
- Example: create a `terraform.tfvars` locally with values you don't commit.

## .envrc vs repository variables

- `.envrc` is local-only and should not be committed (we added it to `.gitignore`).
- The example file `.envrc.example` is committed so others can copy it.

## GitHub Actions OIDC notes

This repo creates an IAM OIDC provider and a role (`oidc.tf`). The role is configured so GitHub Actions can assume it using short-lived tokens (no long-lived AWS credentials in Secrets).

After applying Terraform, use the output `github_actions_role_arn` and set it as a repository variable in GitHub (Repository → Settings → Secrets and variables → Variables) named e.g. `AWS_ROLE_ARN`.

In your workflow you should enable `id-token: write` permission and then configure the AWS credentials action to assume the role.

Example (workflow snippet):

```yaml
permissions:
	id-token: write
	contents: read

- name: Configure AWS Credentials
	uses: aws-actions/configure-aws-credentials@v4
	with:
		role-to-assume: ${{ vars.AWS_ROLE_ARN }}
		aws-region: us-west-2
```

Notes on the role-to-assume value:
- ARNs are not secrets; they are resource identifiers. You can hardcode the ARN in a workflow, but using a repo variable (or environment) improves flexibility.

## Deploying `index.html` to the EC2 instance

The example workflow uses EC2 Instance Connect (permission: `ec2-instance-connect:SendSSHPublicKey`) to push a temporary SSH public key to the instance, valid for ~60 seconds, which avoids storing permanent SSH keys. Alternatives include:

- Having the instance pull assets from an S3 bucket (recommended for CI-driven static deployments)
- Using SSM Session Manager or Run Command
- CodeDeploy or other deployment services

If you prefer S3 pull model, grant the instance an IAM role that can read a specific S3 bucket and use a userdata/script to fetch the latest index.html.

## Security & operational recommendations

- Keep `.terraform` directories and `*.tfstate` out of git (they are ignored by `.gitignore`).
- Keep the `.terraform.lock.hcl` in source control — it pins provider versions for reproducible runs.
- Rotate and manage AWS credentials responsibly; prefer OIDC in CI.
- For ACM DNS validation records, do NOT delete the validation records — ACM uses them for renewals.

## How to get the GitHub Actions role ARN (after apply)

After `terraform apply`, Terraform will output `github_actions_role_arn`. Copy that value and add as a repository variable in GitHub (or use it directly in your workflow if you prefer).

## Troubleshooting

- Provider errors: run `terraform init -upgrade`.
- TLS provider missing: ensure `provider.tf` includes a `tls` required_provider and run `terraform init`.
- DNS/certificate validation failures: check Route53 NS records and DNS propagation.

## Next steps (suggested)

- Consider switching file deployment to S3 + instance pull or use SSM for a more robust CI deployment path.
- Add a `CONTRIBUTING.md` or short onboarding doc if more people will work on this repo.

---

If you want, I can also:
- Add a short `CONTRIBUTING.md` with exact developer commands
- Add a small script to copy `.envrc.example` to `.envrc`
- Add a `Makefile` with common commands (`init`, `plan`, `apply`)

Tell me which of those you'd like and I'll add them next.