#!/usr/bin/env bash
set -euo pipefail
CANONICAL_WS="/home/kavia/workspace/code-generation/resident-directory-manager-292532-292577/resident_directory_native_app/.workspace_env"
[ -f "$CANONICAL_WS" ] && source "$CANONICAL_WS"
: "${WORKSPACE:?}"
export RESIDENT_DB_PATH="${RESIDENT_DB_PATH:-$WORKSPACE/residents.db}"
cd "$WORKSPACE"
# Build (smoke test)
bash .init/build.sh >/dev/null 2>&1 || true
# start app
bash .init/start.sh
PIDFILE="$WORKSPACE/.app_pid"
# wait up to 30s with exponential backoff
timeout=30; elapsed=0; interval=1
while [ $elapsed -lt $timeout ]; do
  if [ -f "$PIDFILE" ]; then break; fi
  sleep $interval; elapsed=$((elapsed+interval)); interval=$(( interval<8 ? interval*2 : interval ))
done
if [ ! -f "$PIDFILE" ]; then echo 'ERROR: .app_pid not created' >&2; tail -n 200 "$WORKSPACE/app.log" 2>/dev/null || true; exit 2; fi
read -r PID PGID START_TIME < "$PIDFILE" || true
if ! kill -0 "$PID" >/dev/null 2>&1; then echo "ERROR: process $PID not running" >&2; tail -n 200 "$WORKSPACE/app.log" 2>/dev/null || true; bash .init/stop.sh || true; exit 3; fi
# run tests
if ! bash .init/test.sh; then echo 'PYTEST_FAILED' >&2; tail -n 200 "$WORKSPACE/app.log" 2>/dev/null || true; bash .init/stop.sh || true; exit 4; fi
# evidence checks
if [ ! -f "$RESIDENT_DB_PATH" ]; then echo 'ERROR: DB missing' >&2; bash .init/stop.sh || true; exit 5; fi
# stop app
bash .init/stop.sh || true
# capture last 50 lines of app.log as evidence
echo "VALIDATION_OK: DB=$RESIDENT_DB_PATH"
echo '--- app.log (last 50 lines) ---'
tail -n 50 "$WORKSPACE/app.log" 2>/dev/null || true
exit 0
