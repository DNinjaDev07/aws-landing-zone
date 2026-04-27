# AWS Landing Zone

![Architecture](docs/aws-landing-zone-architecture.drawio.png)

A multi-account AWS Landing Zone built with Terraform and deployed via GitHub
Actions using OIDC (no long-lived AWS keys in CI).

## What's in here

| Component | Purpose |
|---|---|
| `bootstrap/state` | S3 remote state bucket (versioned, AES256, S3 native locking) |
| `bootstrap/github-oidc` | GitHub OIDC provider + IAM role for CI |
| `modules/organization` | Workloads + Sandbox OUs and three SCPs (region restriction, deny root usage, require encryption) attached to the Workloads OU |
| `modules/iam-baseline` | IAM role for AWS Config in the workload account |
| `modules/logging` | Org-wide CloudTrail to an encrypted S3 bucket in the management account, with lifecycle to STANDARD_IA at 90d and expiry at 365d |
| `modules/compliance` | AWS Config recorder + delivery channel, three managed rules (EC2 IMDSv2, restricted SSH, S3 encryption), SNS topic for `NON_COMPLIANT` notifications |
| `environments/workload-dev` | Composes the four modules into a single root |
| `.github/workflows/terraform.yml` | tfsec + Checkov scan -> plan -> manual-approval -> apply |

The scope is governance and detection. VPC provisioning and Lambda-based
auto-remediation are out of scope. AWS Config evaluates the three managed
rules, and the SNS topic emails non-compliant findings to an operator.

## Architecture summary

### Management account
- Terraform state S3 bucket
- GitHub OIDC provider + role
- AWS Organizations OUs and SCPs
- Organization CloudTrail and log archive bucket

### Workload-dev account (Workloads OU)
- AWS Config recorder + delivery channel
- Three managed Config rules
- SNS topic with email subscription for compliance notifications

## CI/CD pipeline

| Stage | What runs |
|---|---|
| `tf-scan` | tfsec + Checkov (soft-fail) |
| `tf-plan` | OIDC auth, `terraform plan`, plan uploaded as artifact |
| `tf-apply` | Downloads the plan artifact and applies on every push to `main` |

The workflow targets `environments/workload-dev` only. You apply the two
`bootstrap/` roots locally one time. They create the state bucket and the
IAM role that CI itself depends on, so CI cannot bootstrap them.

## Prerequisites

1. Terraform `>= 1.10` (S3 native state locking).
2. AWS CLI configured against the management account with permissions to
   create IAM, S3, and Organizations resources.
3. A GitHub repository at `DNinjaDev07/aws-landing-zone`.
4. Bash (for `scripts/generate-backend-dev.sh`).
5. Organizations trusted access for CloudTrail enabled in the management
   account before applying the logging module:

   ```bash
   aws organizations enable-aws-service-access \
     --service-principal cloudtrail.amazonaws.com
   ```

## Reproduce the project

### 1. Clone

```bash
git clone git@github.com:DNinjaDev07/aws-landing-zone.git
cd aws-landing-zone
```

### 2. Bootstrap remote state (one-time)

```bash
cd bootstrap/state
terraform init
terraform apply
terraform output
```

### 3. Bootstrap GitHub OIDC (one-time)

```bash
cd ../github-oidc
terraform init
terraform apply
terraform output
```

The trust policy is scoped to:

- `repo:DNinjaDev07/aws-landing-zone:ref:refs/heads/main`
- `repo:DNinjaDev07/aws-landing-zone:pull_request`

The role uses `AdministratorAccess` for the bootstrap phase. Replace it
with a least-privilege deploy policy once your resource set stabilizes.

### 4. Configure GitHub repo

1. The workflow reads no GitHub Actions secrets. OIDC handles auth.
2. Update `AWS_OIDC_ROLE_ARN` in `.github/workflows/terraform.yml` if your
   `bootstrap/github-oidc` output ARN differs.

### 5. Generate workload backend config

```bash
cd ../..
./scripts/generate-backend-dev.sh
```

Writes `environments/workload-dev/backend-dev.hcl` (gitignored).

### 6. Init and plan workload-dev locally

```bash
cd environments/workload-dev
cp terraform.tfvars.example terraform.tfvars   # fill in real values
terraform init -backend-config=backend-dev.hcl -reconfigure
terraform plan
```

Keep regions consistent across `bootstrap/state`, `bootstrap/github-oidc`,
`backend-dev.hcl`, and `terraform.tfvars`.

### 7. Apply via CI

```bash
git add .
git commit -m "deploy workload-dev"
git push origin main
```

GitHub Actions runs scan, plan, and apply on every push to `main`.

## Tear down

`scripts/teardown.sh` destroys everything in reverse order:

1. `environments/workload-dev` (detaches SCPs, stops Config recorder, empties
   versioned buckets, strips `prevent_destroy` lifecycle blocks, then
   `terraform destroy`)
2. `bootstrap/github-oidc`
3. `bootstrap/state` (empties the state bucket first)

```bash
./scripts/teardown.sh                # interactive
FORCE=1 ./scripts/teardown.sh        # no prompts
SKIP_BOOTSTRAP=1 ./scripts/teardown.sh   # leave state + OIDC intact
```

## Troubleshooting

### `Credentials could not be loaded` in CI

- Workflow has `permissions: id-token: write` and `contents: read`.
- IAM trust `sub` matches your repo, branch, and event type.
- `role-to-assume` and `aws-region` are correct.

### Backend config not found

```bash
./scripts/generate-backend-dev.sh
```

## Next steps

For a team setting, add a GitHub Environment called `production` to the
`tf-apply` job and require a human reviewer before apply. In a single-engineer
setup you commit, review the diff yourself, then push to deploy, so the
reviewer gate adds friction without adding safety.
