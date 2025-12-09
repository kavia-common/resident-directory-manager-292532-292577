#!/usr/bin/env bash
set -euo pipefail
CANONICAL_WS="/home/kavia/workspace/code-generation/resident-directory-manager-292532-292577/resident_directory_native_app/.workspace_env"
[ -f "$CANONICAL_WS" ] && source "$CANONICAL_WS"
: "${WORKSPACE:?}"
cd "$WORKSPACE"
LOGFILE="$WORKSPACE/app.log"
PIDFILE="$WORKSPACE/.app_pid"
# start the app in background, record pid, pgid and timestamp
# if already running, no-op
if [ -f "$PIDFILE" ]; then
  read -r PID PGID START_TIME < "$PIDFILE" || true
  if [ -n "${PID:-}" ] && kill -0 "$PID" >/dev/null 2>&1; then
    echo "ALREADY_RUNNING $PID"
    exit 0
  else
    rm -f "$PIDFILE"
  fi
fi
# Launch via python module so imports resolve; app should handle DISPLAY safely
nohup python3 -u -c "import src.app as _app; _app.main()" >>"$LOGFILE" 2>&1 &
PID=$!
PGID=$(ps -o pgid= $PID | tr -d ' ')
START_TIME=$(date +%s)
echo "$PID $PGID $START_TIME" > "$PIDFILE"
# ensure file persisted
sleep 0.2
echo "STARTED $PID"
