# AWS Landing Zone with Compliance Automation

![Architecture](docs/aws-landing-zone-architecture.drawio.png)

## Proposed Architecture

A Terraform-based AWS Landing Zone deployed through a secure CI/CD pipeline. The architecture spans two accounts under an AWS Organization, combining preventive controls (SCPs), detective controls (AWS Config), and automated remediation (Lambda).

### CI/CD Pipeline

| Stage | Purpose |
|-------|---------|
| Security Scan | Checkov and tfsec scan all Terraform for misconfigurations |
| Terraform Plan | Plan output posted as a PR comment for review |
| Manual Approval | GitHub Environment protection rule gates apply |
| Terraform Apply | OIDC-authenticated apply — no stored AWS credentials |
| Lambda Tests | pytest + Bandit run against remediation functions |

### Management Account

| Component | Purpose |
|-----------|---------|
| Terraform State | S3 bucket (encrypted, versioned) with S3 locking enabled |
| OIDC Provider | GitHub Actions trust — federated authentication via `sts:AssumeRoleWithWebIdentity` |
| AWS Organizations | Workloads OU and Sandbox OU with member accounts |
| Service Control Policies | Region restriction, deny root usage, require encryption |
| Organization CloudTrail | Multi-region trail → S3 log archive (90d → Standard-IA, 365d expire) |
| IAM Baseline | Account password policy, cross-account Terraform execution role |

### Workload-Dev Account (Workloads OU)

| Component | Purpose |
|-----------|---------|
| VPC | 2 public + 2 private subnets across 2 AZs, single NAT Gateway, VPC Flow Logs |
| AWS Config | 3 managed rules: EC2 IMDSv2, restricted SSH, S3 encryption |
| EventBridge | Matches `NON_COMPLIANT` evaluation results from Config |
| Lambda | `remediate_public_sg` — revokes 0.0.0.0/0 SSH rules from security groups |
| Lambda | `remediate_imdsv1` — enforces IMDSv2 on non-compliant EC2 instances |
| SNS | Email notifications on every compliance violation |

## Proposed Process Flow

```text
 Developer pushes code
        │
        ▼
 ┌─────────────────────────────────────────────────────────┐
 │  GitHub Actions Pipeline                                │
 │                                                         │
 │  1. Checkov + tfsec ─► Security scan all Terraform      │
 │  2. terraform plan  ─► Post plan as PR comment          │
 │  3. Manual approval ─► Reviewer approves in GitHub UI   │
 │  4. terraform apply ─► OIDC AssumeRole into AWS         │
 │  5. pytest + Bandit ─► Test and scan Lambda functions    │
 └─────────────────────────────────────────────────────────┘
        │
        ▼
 ┌─────────────────────────────────────────────────────────┐
 │  Management Account                                     │
 │                                                         │
 │  AWS Organizations ──► Workloads OU + Sandbox OU        │
 │  SCPs ──────────────► Region lock, deny root, enforce   │
 │                        encryption (preventive controls)  │
 │  CloudTrail ────────► S3 log archive (org-wide)         │
 └─────────────────────────────────────────────────────────┘
        │ SCP policy inheritance
        ▼
 ┌─────────────────────────────────────────────────────────┐
 │  Workload-Dev Account                                   │
 │                                                         │
 │  VPC ───────────────► Networking foundation             │
 │                                                         │
 │  AWS Config ────────► Continuously evaluates resources  │
 │       │                                                 │
 │       │ NON_COMPLIANT                                   │
 │       ▼                                                 │
 │  EventBridge ───┬──► Lambda (auto-remediate resource)   │
 │                 │                                       │
 │                 └──► SNS (email alert to operator)      │
 └─────────────────────────────────────────────────────────┘
```
