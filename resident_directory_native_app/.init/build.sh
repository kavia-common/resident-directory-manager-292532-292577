#!/usr/bin/env bash
set -euo pipefail
CANONICAL_WS="/home/kavia/workspace/code-generation/resident-directory-manager-292532-292577/resident_directory_native_app/.workspace_env"
[ -f "$CANONICAL_WS" ] && source "$CANONICAL_WS"
: "${WORKSPACE:?}"
cd "$WORKSPACE"
# Minimal build: import smoke-test
python3 - <<'PY'
import importlib, sys
try:
    importlib.import_module('src')
    importlib.import_module('src.app')
    print('BUILD_OK')
except Exception as e:
    print('BUILD_IMPORT_FAILED', e, file=sys.stderr)
    raise
PY
