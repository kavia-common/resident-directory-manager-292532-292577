#!/usr/bin/env bash
set -euo pipefail
CANONICAL_WS="/home/kavia/workspace/code-generation/resident-directory-manager-292532-292577/resident_directory_native_app/.workspace_env"
[ -f "$CANONICAL_WS" ] && source "$CANONICAL_WS"
: "${WORKSPACE:?}"
export RESIDENT_DB_PATH="${RESIDENT_DB_PATH:-$WORKSPACE/residents.db}"
cd "$WORKSPACE"
# Run pytest - quiet
python3 -m pytest -q tests
