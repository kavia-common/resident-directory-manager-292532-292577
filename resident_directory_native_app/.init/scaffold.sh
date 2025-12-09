#!/usr/bin/env bash
set -euo pipefail
# scaffold project structure and minimal PyQt6 app
WS="/home/kavia/workspace/code-generation/resident-directory-manager-292532-292577/resident_directory_native_app"
mkdir -p "$WS/src" "$WS/tests" || true
ENVFILE="$WS/.workspace_env"
[ -f "$ENVFILE" ] && cp "$ENVFILE" "$ENVFILE.bak.$(date +%s)" || true
cat > "$ENVFILE" <<'SH'
export WORKSPACE="${WS}"
export RESIDENT_DB_PATH="${WS}/residents.db"
SH
chmod 644 "$ENVFILE"
# ensure __init__.py exists
touch "$WS/src/__init__.py"
# write runtime-safe app.py (backup if exists)
APP="$WS/src/app.py"
[ -f "$APP" ] && cp "$APP" "$APP.bak.$(date +%s)" || true
cat > "$APP" <<'PY'
import sys, os, logging
logging.basicConfig(stream=sys.stdout, level=logging.INFO)
logger = logging.getLogger('resident_app')

def get_db_path(workspace=None):
    if workspace:
        return os.path.normpath(os.path.abspath(os.path.join(workspace, 'residents.db')))
    env = os.environ.get('RESIDENT_DB_PATH')
    if env:
        return os.path.normpath(os.path.abspath(env))
    base = os.path.dirname(__file__)
    return os.path.normpath(os.path.abspath(os.path.join(base, '..', 'residents.db')))

def build_window(db_path):
    # Delay Qt imports until runtime so imports are safe in headless contexts
    from PyQt6 import QtWidgets
    app = QtWidgets.QApplication(sys.argv)
    win = QtWidgets.QWidget()
    win.setWindowTitle('Resident Directory - Dev')
    win.setGeometry(100, 100, 400, 200)
    label = QtWidgets.QLabel(f'DB: {db_path}', parent=win)
    label.move(10, 10)
    win.show()
    logger.info('window shown with DB=%s', db_path)
    return app

def run_app(workspace=None):
    db = get_db_path(workspace)
    logger.info('starting app with db=%s', db)
    app = build_window(db)
    return app.exec()

if __name__ == '__main__':
    run_app()
PY
# start.sh (backup then write)
START="$WS/start.sh"
[ -f "$START" ] && cp "$START" "$START.bak.$(date +%s)" || true
cat > "$START" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
# source canonical env
if [ -f "$(dirname "$0")/.workspace_env" ]; then source "$(dirname "$0")/.workspace_env"; fi
: "${WORKSPACE:?}"
LOG="$WORKSPACE/app.log"
PIDFILE="$WORKSPACE/.app_pid"
CMDFILE="$WORKSPACE/.app_cmd"
# ensure DISPLAY is available via system profile if present
source /etc/profile.d/resident_dir_env.sh >/dev/null 2>&1 || true
# avoid starting if already running and matches signature
if [ -f "$PIDFILE" ]; then
  read -r meta < "$PIDFILE" || true
  pid=$(echo "$meta" | awk -F' ' '{print $1}')
  if [ -n "$pid" ] && [ -d "/proc/$pid" ]; then
    cmdline=$(tr '\0' ' ' < /proc/$pid/cmdline 2>/dev/null || true)
    if echo "$cmdline" | grep -q "src/app.py"; then echo "$pid" > "$PIDFILE"; exit 0; fi
  fi
fi
# start process in new session and capture pid and pgid
setsid env DISPLAY=:99 python3 "$WORKSPACE/src/app.py" >>"$LOG" 2>&1 &
PID=$!
# allow proc to settle
sleep 0.2
if [ ! -d "/proc/$PID" ]; then echo 'ERROR: failed to start process' >&2; exit 4; fi
PGID=$(ps -o pgid= -p $PID | tr -d ' ')
START_TIME=$(stat -c %Y /proc/$PID)
# write pidfile with metadata (pid pgid start_time)
echo "$PID $PGID $START_TIME" > "$PIDFILE"
echo "python3 src/app.py" > "$CMDFILE"
exit 0
SH
chmod +x "$START"
# stop.sh (backup then write)
STOP="$WS/stop.sh"
[ -f "$STOP" ] && cp "$STOP" "$STOP.bak.$(date +%s)" || true
cat > "$STOP" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [ -f "$(dirname "$0")/.workspace_env" ]; then source "$(dirname "$0")/.workspace_env"; fi
: "${WORKSPACE:?}"
PIDFILE="$WORKSPACE/.app_pid"
CMDFILE="$WORKSPACE/.app_cmd"
if [ ! -f "$PIDFILE" ]; then echo 'no pid'; exit 0; fi
read -r PID PGID START_TIME < "$PIDFILE" || true
if [ -n "${PID:-}" ] && [ -d "/proc/$PID" ]; then
  # verify start time to reduce PID reuse risk
  actual_start=$(stat -c %Y /proc/$PID 2>/dev/null || echo 0)
  cmdline=$(tr '\0' ' ' < /proc/$PID/cmdline 2>/dev/null || true)
  if [ "$actual_start" = "$START_TIME" ] && echo "$cmdline" | grep -q "src/app.py"; then
    kill -TERM -$PGID >/dev/null 2>&1 || true
    sleep 1
    if kill -0 "$PID" >/dev/null 2>&1; then kill -KILL -$PGID >/dev/null 2>&1 || true; fi
  else
    echo "PID verification failed; not killing. Removing stale pidfile" >&2
  fi
fi
rm -f "$PIDFILE" "$CMDFILE" || true
exit 0
SH
chmod +x "$STOP"
# minimal README
README="$WS/README.md"
[ -f "$README" ] && cp "$README" "$README.bak.$(date +%s)" || true
cat > "$README" <<'MD'
Resident Directory native app (development scaffolding).
Use start.sh and stop.sh in the workspace root. Ensure you source .workspace_env or export WORKSPACE before running scripts.
MD
exit 0
