# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Terraform infrastructure-as-code repository provisioning a web stack on AWS for `gillzhub.com`. Manages an ALB with HTTPS, EC2 Windows/IIS instance, Route53 DNS, ACM certificates, S3 deployment bucket, and GitHub Actions OIDC integration.

## Common Commands

```bash
# Initialize Terraform (fetch providers, configure S3 backend)
terraform init

# Preview infrastructure changes
terraform plan

# Apply infrastructure changes
terraform apply

# Format HCL files (CI enforces this)
terraform fmt

# Check syntax/structure
terraform validate

# Re-fetch providers after upstream changes
terraform init -upgrade
```

The bootstrap module (`bootstrap/`) has its own state and is initialized separately:
```bash
cd bootstrap && terraform init && terraform apply -var="bucket_name=<name>"
```

## Architecture

**Traffic flow:** Internet → ALB (port 443/HTTPS with ACM cert) → Target Group (port 80) → EC2 Windows/IIS instance

**Key resources by file:**
- `provider.tf` — AWS provider config + S3/DynamoDB remote backend
- `main.tf` — Route53 hosted zone, EC2 instance (Windows Server, IIS via user data), data sources (default VPC/subnets, latest Windows AMI, caller identity)
- `lb.tf` — ALB, target group, HTTPS listener
- `security.tf` — Security groups: ALB (inbound 443 from world), EC2 (inbound 80 from ALB only)
- `certificates.tf` — ACM certificate + Route53 DNS validation records
- `oidc.tf` — GitHub Actions OIDC provider + IAM role (scoped to this repo)
- `iam_instance.tf` — EC2 instance IAM role for SSM + S3 read access
- `s3.tf` — Deployment bucket (versioned, public access blocked)
- `variables.tf` / `outputs.tf` — Input variables and output values
- `index.html` — Static site content deployed to EC2/IIS

**State management:** Remote S3 backend (bucket name configured via `-backend-config` in CI and local init) with DynamoDB locking (`terraform-state-locks`), encryption enabled.

**Defaults:** Region `us-west-2`, instance type `t3.small`, environment `dev`, domain `forfun.gillzhub.com`. Uses default VPC (first 2 subnets for ALB).

## CI/CD (GitHub Actions)

- `.github/workflows/terraform-plan-apply.yml` — Two-job workflow: `plan` job runs on PRs and pushes to `main` (fmt, init, validate, plan, PR comment); `apply` job runs on push to `main` only, gated by the `production` GitHub Environment (requires manual approval). Plan artifact is passed between jobs. Uses OIDC for AWS auth. Concurrency group prevents parallel runs.
- `.github/workflows/deploy-site.yml` — On push to `main` (when `index.html` changes) or manual dispatch: uploads `index.html` to S3, sends SSM command to EC2 to download via presigned URL and restart IIS.

## Conventions

- Resources tagged with `Name = "${var.domain_name}-<resource>"` and `Environment = var.environment`, merged with `var.tags`
- ACM certificates use `create_before_destroy` lifecycle rule
- Certificate validation records use `for_each` over `domain_validation_options`
- No hardcoded credentials; CI uses OIDC, local dev uses AWS profiles via `.envrc`/direnv
- `.terraform.lock.hcl` is committed for reproducible provider versions
- Do not delete ACM DNS validation records (needed for auto-renewal)

## Working Style — User Preferences

**User context:** Senior DevOps engineer learning AI/agent tooling. Dual goals: build real AWS infrastructure and learn how to leverage AI for productivity.

**Explanation level: Thorough teacher mode**
- Explain the "why" behind every infrastructure decision — trade-offs, alternatives, and AWS best practices
- Treat each task as a learning opportunity, not just execution
- For AI/agent topics (MCP servers, agents, multi-agent systems): explain concepts and mental models first, then build together

**Autonomy: Write code freely, user reviews via PR**
- Write Terraform code, run `fmt`, `validate`, and `plan` freely
- Never run `terraform apply` locally — all applies go through CI on `main`
- User controls what hits `main` via PR review

**Terraform patterns:**
- Start flat (current style), introduce modules gradually as complexity grows
- Teach module patterns along the way when extracting reusable components
- Follow existing naming/tagging conventions

**AWS learning roadmap (areas of interest beyond current repo):**
- Containers: ECS, EKS, Fargate
- Serverless: Lambda, API Gateway, Step Functions
- Networking: VPCs, Transit Gateway, PrivateLink, multi-account networking
- Platform engineering: Landing zones, Control Tower, multi-account strategy, IaC at scale

**AI/agent learning roadmap:**
- Currently brand new to MCP servers and agent frameworks
- Goal: personal productivity — agents that query AWS accounts, read Terraform state, automate runbooks
- Interested in eventually having agents communicate with each other
- When teaching AI concepts: explain the mental model first, then implement together
