# aws-infrastructure — Terraform + AWS setup

This repository contains Terraform configuration to provision a small web stack for `gillzhub.com` (ALB, EC2 Windows IIS, Route53, ACM certificates, and GitHub Actions OIDC setup).

This README is written for contributors who may be unfamiliar with Terraform or AWS CLI. It explains how to prepare your local environment, initialize Terraform, and deploy safely.

## Quick checklist (high level)

- Install Terraform (v1.X+ recommended)
- Install AWS CLI and configure an AWS profile
- Copy `.envrc.example` to `.envrc` and set your AWS_PROFILE (or export env vars manually)
- Run `terraform init`, `terraform plan`, and `terraform apply` from the `infra/` directory

## Prerequisites

- macOS / Linux / Windows with a shell
- An AWS account with appropriate permissions (create roles, S3 buckets for backend, Route53 access, etc.)
- Terraform installed: https://developer.hashicorp.com/terraform
- AWS CLI installed and configured: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

## Repository layout

```
├── infra/                 # Terraform configuration (all .tf files)
│   ├── provider.tf        # Backend and provider configuration (S3 backend + provider blocks)
│   ├── main.tf            # Route53, EC2 instance, data sources
│   ├── lb.tf              # ALB, target group, HTTPS listener
│   ├── security.tf        # Security groups (ALB + EC2)
│   ├── certificates.tf    # ACM certificate + DNS validation
│   ├── oidc.tf            # GitHub Actions OIDC provider + IAM role
│   ├── iam_instance.tf    # EC2 instance IAM role (SSM + S3 read)
│   ├── s3.tf              # Deployment S3 bucket
│   ├── budget.tf          # AWS Budget + SNS alerts
│   ├── variables.tf       # Input variables
│   ├── outputs.tf         # Output values
│   └── .terraform.lock.hcl # Provider version lock file
├── site/                  # Web application content
│   └── index.html         # Static site deployed to EC2/IIS
├── bootstrap/             # One-time setup for S3 backend + DynamoDB lock table
├── .github/workflows/
│   ├── terraform-plan-apply.yml  # Plan on PR, apply on merge to main
│   └── deploy-site.yml          # Deploy site/ content to EC2 via S3 + SSM
├── .envrc.example         # Example local environment file (do NOT commit your real .envrc)
├── CLAUDE.md              # AI assistant instructions
└── .gitignore             # Excludes local Terraform files and secrets
```

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

All Terraform commands run from the `infra/` directory:

1. Install required providers and initialize the workspace:

```bash
cd infra
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
- If you change provider blocks, sometimes you must reinitialize or remove `infra/.terraform` locally before init.

## Variables and sensitive data

- Do NOT commit secrets such as `*.tfvars` files with credentials. These are ignored by `.gitignore`.
- Use variable definitions in `infra/variables.tf` and pass values via CLI or a local-only `terraform.tfvars` that is not committed.
- Example: create a `terraform.tfvars` locally in `infra/` with values you don't commit.

## .envrc vs repository variables

- `.envrc` is local-only and should not be committed (we added it to `.gitignore`).
- The example file `.envrc.example` is committed so others can copy it.

## GitHub Actions OIDC notes

This repo creates an IAM OIDC provider and a role (`infra/oidc.tf`). The role is configured so GitHub Actions can assume it using short-lived tokens (no long-lived AWS credentials in Secrets).

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

## Deploying `site/index.html` to the EC2 instance

The deploy workflow (`.github/workflows/deploy-site.yml`) uploads `site/index.html` to an S3 deployment bucket, then uses SSM Run Command to have the EC2 instance download and serve it via IIS. This triggers on pushes to `main` that change files in `site/`, or via manual dispatch.

Alternatives include:
- CodeDeploy or other deployment services
- SSM Session Manager for ad-hoc changes

## Security & operational recommendations

- Keep `.terraform` directories and `*.tfstate` out of git (they are ignored by `.gitignore`).
- Keep `infra/.terraform.lock.hcl` in source control — it pins provider versions for reproducible runs.
- Rotate and manage AWS credentials responsibly; prefer OIDC in CI.
- For ACM DNS validation records, do NOT delete the validation records — ACM uses them for renewals.

## How to get the GitHub Actions role ARN (after apply)

After `terraform apply`, Terraform will output `github_actions_role_arn`. Copy that value and add as a repository variable in GitHub (or use it directly in your workflow if you prefer).

## Troubleshooting

- Provider errors: run `terraform init -upgrade` from `infra/`.
- TLS provider missing: ensure `infra/provider.tf` includes a `tls` required_provider and run `terraform init`.
- DNS/certificate validation failures: check Route53 NS records and DNS propagation.
