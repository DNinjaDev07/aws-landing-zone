# AWS Landing Zone with Compliance Automation

![Architecture](docs/aws-landing-zone-architecture.drawio.png)

This repository builds an AWS Landing Zone in phases using Terraform and GitHub Actions with OIDC.

## Current Scope

Implemented in this repository today:

1. Bootstrap remote Terraform state in AWS S3 with S3 native state locking.
2. Bootstrap GitHub OIDC provider and IAM role for GitHub Actions.
3. Workload environment backend configuration and examples.
4. CI workflow scaffold at `.github/workflows/terraform.yml`.

Core landing zone modules (org/SCPs, VPC, logging, compliance automation) are the next implementation phases.

## Target Architecture Context

### CI/CD Pipeline

| Stage | Purpose |
|---|---|
| Security Scan | Checkov and tfsec scan Terraform for misconfigurations |
| Terraform Plan | Plan output is reviewed before apply |
| Manual Approval | GitHub Environment protection rule gates apply |
| Terraform Apply | OIDC-authenticated apply with no stored AWS credentials |
| Lambda Tests | pytest + Bandit run against remediation functions |

### Management Account

| Component | Purpose |
|---|---|
| Terraform State | S3 bucket (encrypted, versioned) with S3 locking enabled |
| OIDC Provider | GitHub Actions trust via `sts:AssumeRoleWithWebIdentity` |
| AWS Organizations | Workloads OU and Sandbox OU with member accounts |
| Service Control Policies | Region restriction, deny root usage, require encryption |
| Organization CloudTrail | Multi-region trail to S3 log archive (90d to Standard-IA, 365d expire) |
| IAM Baseline | Account password policy and cross-account Terraform execution role |

### Workload-Dev Account (Workloads OU)

| Component | Purpose |
|---|---|
| VPC | 2 public + 2 private subnets across 2 AZs, single NAT Gateway, VPC Flow Logs |
| AWS Config | 3 managed rules: EC2 IMDSv2, restricted SSH, S3 encryption |
| EventBridge | Matches `NON_COMPLIANT` evaluation results from Config |
| Lambda | `remediate_public_sg` revokes `0.0.0.0/0` SSH rules from security groups |
| Lambda | `remediate_imdsv1` enforces IMDSv2 on non-compliant EC2 instances |
| SNS | Email notifications on compliance violations |

## Important Execution Model

Terraform runs per root directory. Running `terraform apply` in one root does not apply other roots.

| Root | Purpose | Applied Separately |
|---|---|---|
| `bootstrap/state` | Create remote state bucket | Yes |
| `bootstrap/github-oidc` | Create GitHub OIDC trust + IAM role | Yes |
| `environments/workload-dev` | Main landing-zone environment | Yes |

## Prerequisites

1. Terraform `>= 1.6`.
2. AWS CLI configured with credentials that can create IAM/S3 resources in your management account.
3. GitHub repository: `DNinjaDev07/aws-landing-zone`.
4. Bash shell (for `scripts/generate-backend-dev.sh`).

## Reproduce the Project (Step-by-Step)

### 1. Clone and enter repository

```bash
git clone git@github.com:DNinjaDev07/aws-landing-zone.git
cd aws-landing-zone
```

### 2. Bootstrap Terraform state (one-time)

```bash
cd bootstrap/state
terraform init
terraform plan
terraform apply
terraform output
```

Expected outputs include:

1. `state_bucket_name`
2. `state_bucket_region`

### 3. Bootstrap GitHub OIDC (one-time)

```bash
cd ../github-oidc
terraform init
terraform plan
terraform apply
terraform output
```

Expected outputs include:

1. `github_oidc_provider_arn`
2. `github_oidc_role_arn`

The OIDC trust policy is scoped to:

1. `repo:DNinjaDev07/aws-landing-zone:ref:refs/heads/main`
2. `repo:DNinjaDev07/aws-landing-zone:pull_request`

### 4. Generate backend config for workload-dev

```bash
cd ../..
./scripts/generate-backend-dev.sh
```

This writes:

1. `environments/workload-dev/backend-dev.hcl`

Note: `backend-dev.hcl` is intentionally gitignored.

### 5. Initialize workload-dev root with remote backend

```bash
cd environments/workload-dev
cp terraform.tfvars.example terraform.tfvars
terraform init -backend-config=backend-dev.hcl -reconfigure
terraform plan
```

Important: keep regions consistent across:

1. `bootstrap/state` provider region
2. `bootstrap/github-oidc` provider region
3. `environments/workload-dev/backend-dev.hcl`
4. `environments/workload-dev/terraform.tfvars`

### 6. Configure and run CI workflow

Workflow file: `.github/workflows/terraform.yml`.

Set `role-to-assume` to the `github_oidc_role_arn` output from `bootstrap/github-oidc`.

Push to `main` to trigger pipeline:

```bash
git add .
git commit -m "your commit message"
git push origin main
```

## Pipeline Flow (Current)

1. `tf-scan`: tfsec + Checkov.
2. `tf-plan`: OIDC auth + Terraform init/plan for `environments/workload-dev`.
3. `tf-apply`: scaffold exists and is completed in later phases.

The workflow targets `environments/workload-dev` only. It does not apply `bootstrap/state` or `bootstrap/github-oidc`.

## Process Flow

```text
bootstrap/state apply
    -> creates remote Terraform state bucket
bootstrap/github-oidc apply
    -> creates GitHub OIDC provider + IAM role
generate backend-dev.hcl
    -> points workload root to remote backend
workload-dev init/plan/apply
    -> deploys landing-zone environment stack
GitHub Actions (OIDC)
    -> scan -> plan -> apply workflow
```

## Troubleshooting

### Error: "Credentials could not be loaded"

Check all of these:

1. Workflow permissions include `id-token: write` and `contents: read`.
2. IAM trust policy `sub` matches your repo/branch/event.
3. Workflow uses the correct role ARN and region.

### Error: backend config not found

Regenerate backend file:

```bash
./scripts/generate-backend-dev.sh
```

## Next Implementation Phases

1. Organizations + OUs + SCPs module.
2. IAM baseline module (cross-account role and policies).
3. VPC module.
4. Logging module.
5. Compliance module (Config, EventBridge, Lambda remediation, SNS).
6. Complete production-ready plan/apply pipeline flow.
