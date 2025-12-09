#!/usr/bin/env bash
set -euo pipefail
# idempotent dependency installer + DB init for resident-directory app
CANONICAL_WS="/home/kavia/workspace/code-generation/resident-directory-manager-292532-292577/resident_directory_native_app/.workspace_env"
[ -f "$CANONICAL_WS" ] && source "$CANONICAL_WS"
: "${WORKSPACE:?WORKSPACE must be set in canonical .workspace_env}"
# ensure pip is available
python3 -m pip --version >/dev/null 2>&1 || { echo 'ERROR: pip not available' >&2; exit 2; }
REQ="$WORKSPACE/requirements.txt"
if [ ! -f "$REQ" ]; then cat > "$REQ" <<'REQ'
pyqt6==6.*
pytest==7.*
REQ
fi
# Install from requirements with retry/backoff
attempts=3
for i in $(seq 1 $attempts); do
  if python3 -m pip install -r "$REQ" --disable-pip-version-check --quiet; then break; fi
  if [ $i -eq $attempts ]; then echo 'ERROR: pip install from requirements failed' >&2; python3 -m pip --version || true; exit 3; fi
  sleep $((2*i))
done
# Verify imports and print installed versions
python3 - <<'PY'
import importlib,sys,subprocess
mods=('PyQt6','pytest')
for m in mods:
    try:
        importlib.import_module(m)
    except Exception as e:
        sys.stderr.write('ERROR: missing '+m+' - '+str(e)+'\n')
        sys.exit(4)
# show versions
try:
    import pkgutil, pkg_resources
    for m in mods:
        try:
            dist = pkg_resources.get_distribution(m)
            print(f"{m}_INSTALLED={dist.version}")
        except Exception:
            print(f"{m}_INSTALLED=unknown")
except Exception:
    pass
print('IMPORTS_OK')
PY
# Initialize DB schema using Python sqlite3 (idempotent)
DBPATH="${RESIDENT_DB_PATH:-$WORKSPACE/residents.db}"
python3 - <<PY
import sqlite3,os,sys
p=os.path.abspath('$DBPATH')
# ensure directory exists
d=os.path.dirname(p)
if d and not os.path.isdir(d):
    os.makedirs(d, exist_ok=True)
con=sqlite3.connect(p)
cur=con.cursor()
cur.execute('CREATE TABLE IF NOT EXISTS residents (id INTEGER PRIMARY KEY, name TEXT, unit TEXT);')
con.commit()
cur.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='residents';")
if cur.fetchone() is None:
    sys.stderr.write('DB_FAILED\n')
    sys.exit(5)
print('DB_OK:', p)
PY
exit 0
