# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Terraform infrastructure-as-code repository provisioning a serverless web stack on AWS for `gillzhub.com`. Manages CloudFront CDN, S3 static hosting, API Gateway + Lambda guestbook backend, DynamoDB, Route53 DNS, ACM certificates, and GitHub Actions OIDC integration.

## Common Commands

All Terraform commands run from the `infra/` directory:
```bash
cd infra

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

**Traffic flow (static):** Internet → Route53 → CloudFront (CDN) → S3 (React SPA)
**Traffic flow (API):** Internet → Route53 → API Gateway (HTTP API v2) → Lambda (Node.js 22) → DynamoDB

**Key resources by file (`infra/`):**
- `provider.tf` — AWS provider config (us-west-2 + us-east-1 for CloudFront) + S3/DynamoDB remote backend
- `main.tf` — Route53 hosted zone + DNS records (CloudFront alias, API Gateway alias)
- `cloudfront.tf` — CloudFront distribution, S3 site bucket, Origin Access Control
- `api_gateway.tf` — HTTP API v2, Lambda integration, routes, custom domain
- `lambda.tf` — Lambda function, IAM role, CloudWatch logs
- `dynamodb.tf` — Guestbook DynamoDB table
- `certificates.tf` — ACM certificates (CloudFront in us-east-1, API Gateway in us-west-2) + DNS validation
- `oidc.tf` — GitHub Actions OIDC provider + IAM role (scoped to this repo)
- `secrets.tf` — SSM Parameter Store (GitHub OAuth credentials, JWT signing key)
- `s3.tf` — Deployment bucket for Lambda artifacts (versioned, public access blocked)
- `budget.tf` — AWS Budgets + SNS email alerts
- `variables.tf` / `outputs.tf` — Input variables and output values

**Web application:**
- `site/` — React SPA (Vite build) deployed to S3 + CloudFront
- `api/` — Node.js Lambda backend (guestbook with GitHub OAuth)

**State management:** Remote S3 backend (bucket name configured via `-backend-config` in CI and local init) with DynamoDB locking (`terraform-state-locks`), encryption enabled.

**Defaults:** Region `us-west-2`, environment `dev`, domain `forfun.gillzhub.com`.

## CI/CD (GitHub Actions)

- `.github/workflows/terraform-plan-apply.yml` — Two-job workflow: `plan` job runs on PRs and pushes to `main` (fmt, init, validate, plan, PR comment); `apply` job runs on push to `main` only, gated by the `production` GitHub Environment (requires manual approval). Plan artifact is passed between jobs. Uses OIDC for AWS auth. Concurrency group prevents parallel runs.
- `.github/workflows/deploy-site.yml` — On push to `main` (when `site/` changes) or manual dispatch: builds React SPA with Vite, syncs to S3, invalidates CloudFront cache.
- `.github/workflows/deploy-api.yml` — On push to `main` (when `api/` changes) or manual dispatch: builds Lambda ZIP with esbuild, uploads to S3, updates Lambda function code.

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
