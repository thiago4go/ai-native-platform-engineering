#!/usr/bin/env bash
set -euo pipefail

DEMO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="${DEMO_ROOT}/harness/runs"
mkdir -p "${RUN_DIR}"

timestamp() {
  date -u +"%Y%m%dT%H%M%SZ"
}

