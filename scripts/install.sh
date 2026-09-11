#!/bin/bash
#
# install.sh: put the built bundle into Droppy Playground and prove it loaded.
#
# What the DroppyKit MCP server's droppykit_install does, as a script: quit the
# Playground, replace the bundle in its droplet folder, clear quarantine,
# relaunch, and wait until the process has the bundle mapped. Anything set in
# the environment (OW_DEMO) is handed to the Playground through `open --env`.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE="$ROOT/.build/OriWeather.droplet"
PLAYGROUND_ID="iordv.DroppyPlayground"
PROCESS="DroppyPlayground"
DESTINATION_DIR="$HOME/Library/Application Support/Droppy Playground/Droplets/ori-weather"

if [ ! -d "$BUNDLE" ]; then
    echo "error: no $BUNDLE. Run make build first." >&2
    exit 1
fi

# Two notch apps do not share one notch (D8).
if pgrep -x OriNotch >/dev/null; then
    echo "error: OriNotch is running. Quit it first; the Playground and OriNotch never run at once." >&2
    exit 1
fi

if pgrep -x "$PROCESS" >/dev/null; then
    osascript -e "tell application id \"$PLAYGROUND_ID\" to quit" >/dev/null 2>&1 || true
    for _ in $(seq 40); do pgrep -x "$PROCESS" >/dev/null || break; sleep 0.25; done
    pkill -x "$PROCESS" 2>/dev/null || true
    for _ in $(seq 20); do pgrep -x "$PROCESS" >/dev/null || break; sleep 0.25; done
fi

rm -rf "$DESTINATION_DIR"
mkdir -p "$DESTINATION_DIR"
cp -R "$BUNDLE" "$DESTINATION_DIR/"
xattr -dr com.apple.quarantine "$DESTINATION_DIR/OriWeather.droplet" 2>/dev/null || true
echo "Installed $DESTINATION_DIR/OriWeather.droplet"

ENV_ARGS=()
if [ -n "${OW_DEMO:-}" ]; then
    ENV_ARGS=(--env "OW_DEMO=$OW_DEMO")
fi
open -b "$PLAYGROUND_ID" ${ENV_ARGS[@]+"${ENV_ARGS[@]}"}

PID=""
for _ in $(seq 80); do
    PID="$(pgrep -x "$PROCESS" | head -1 || true)"
    [ -n "$PID" ] && break
    sleep 0.25
done
if [ -z "$PID" ]; then
    echo "error: Droppy Playground did not start within 20s." >&2
    exit 1
fi

for second in $(seq 25); do
    if lsof -p "$PID" -Fn 2>/dev/null | grep -q "ori-weather/OriWeather.droplet"; then
        echo "Loaded: Droppy Playground (pid $PID) has OriWeather.droplet mapped after ${second}s."
        exit 0
    fi
    sleep 1
done
echo "NOT loaded: Droppy Playground (pid $PID) has not mapped OriWeather.droplet. Read its Store row." >&2
log show --last 40s --style compact \
    --predicate 'subsystem == "app.getdroppy.Droppy" AND category == "droplets"' | tail -20 >&2
exit 1
