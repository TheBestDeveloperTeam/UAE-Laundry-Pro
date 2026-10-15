#!/usr/bin/env bash
# Drops ALL tables in the cloud DB and re-runs migrations via deploy.php.
# Usage (cPanel Terminal / SSH):
#   cd DEPLOY_ROOT/cloud-api
#   export REBUILD_CONFIRM=1
#   bash scripts/rebuild_cloud_database.sh

set -euo pipefail

if [[ "${REBUILD_CONFIRM:-}" != "1" ]]; then
  echo "This will DROP every table in the database configured in cloud-api/.env"
  echo "Set REBUILD_CONFIRM=1 and run again to proceed."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."
php scripts/deploy.php --fresh
