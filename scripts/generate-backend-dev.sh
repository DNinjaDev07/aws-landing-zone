#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOOTSTRAP_DIR="$ROOT_DIR/bootstrap/state"
WORKLOAD_ENV_DIR="$ROOT_DIR/environments/workload-dev"
OUTPUT_FILE="$WORKLOAD_ENV_DIR/backend-dev.hcl"

if ! command -v terraform >/dev/null 2>&1; then
  echo "[ERROR] terraform is not installed or not in PATH." >&2
  exit 1
fi

if [[ ! -f "$BOOTSTRAP_DIR/terraform.tfstate" ]]; then
  echo "[ERROR] Bootstrap state not found at $BOOTSTRAP_DIR/terraform.tfstate." >&2
  echo "Run bootstrap first: cd bootstrap/state && terraform apply" >&2
  exit 1
fi

pushd "$BOOTSTRAP_DIR" >/dev/null
BUCKET="$(terraform output -raw state_bucket_name)"
REGION="$(terraform output -raw state_bucket_region 2>/dev/null || true)"
popd >/dev/null

if [[ -z "$REGION" ]]; then
  REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-2}}"
  echo "[WARN] state_bucket_region output not found. Falling back to region: $REGION"
  echo "[WARN] Re-run bootstrap apply to persist the new output in state."
fi

cat >"$OUTPUT_FILE" <<EOF
bucket       = "${BUCKET}"
key          = "workload-dev/terraform.tfstate"
region       = "${REGION}"
encrypt      = true
use_lockfile = true
EOF

echo "[OK] Wrote $OUTPUT_FILE"
echo "Next: cd $WORKLOAD_ENV_DIR && terraform init -backend-config=backend-dev.hcl -reconfigure"
