#!/bin/zsh
#
# What the droplet costs the Playground. D6 in one script, after OriNotch's
# energy.sh, pointed at the DroppyPlayground process instead of an app of our
# own: the host is the thing that pays, so the host is what is measured.
#
#   scripts/energy.sh          measure three runs, print the table, write the report
#
# Three runs, a minute of `top` each, same wallpaper, same player state, the
# pointer wherever it was left:
#
#   removed    the droplet taken out of the Playground's folder: the baseline
#   seated     installed with OW_DEMO=1 and "Keep on the notch" on, so it
#              publishes, holds the seat and runs its clock (a 30 minute
#              timer, which should cost nothing in a minute)
#   unseated   the same demo sky with "Keep on the notch" off, so it has a
#              reading, publishes nothing, holds no seat and must hold no timer
#
# The pin is written into the Playground's own preferences for each run, the
# way the droplet stores it (JSON through the host), and whatever the user had
# is put back afterwards.
#
# It fails when a run with the droplet in it wakes the Playground more than
# the baseline does past noise, or when the droplet's own log says a clock
# started while it held no seat and no shelf. The Playground and OriNotch
# never run at once (D8), so it refuses while OriNotch is up.

set -eu

# --- the line, D6 ---------------------------------------------------------

NOISE_WAKEUPS=0.5       # wakeups a second either way that a quiet Mac makes by itself
NOISE_FRACTION=0.2      # or a fifth of the baseline, whichever is larger
NOISE_CPU=0.1           # per cent

SAMPLES=61              # one a second; the first is discarded, so 60 count
SETTLE=20               # seconds between the relaunch and the idle minute

PROCESS=DroppyPlayground
PLAYGROUND_ID=iordv.DroppyPlayground
PIN_KEY=droplet.ori-weather.pinned
FOLDER="$HOME/Library/Application Support/Droppy Playground/Droplets/ori-weather"

root=${0:a:h:h}
cd "$root"

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

say() { print -P "%F{cyan}==%f $*" }
bad() { print -P "%F{red}xx%f $*" >&2; exit 1 }

pgrep -x OriNotch >/dev/null && bad "OriNotch is running; the Playground and OriNotch never run at once (D8)"
[[ -d .build/OriWeather.droplet ]] || bad "no .build/OriWeather.droplet; run make build first"
[[ -d "/Applications/Droppy Playground.app" ]] || bad "Droppy Playground is not installed"

quit_playground() {
    pgrep -x $PROCESS >/dev/null || return 0
    osascript -e "tell application id \"$PLAYGROUND_ID\" to quit" >/dev/null 2>&1 || true
    for _ in {1..40}; do pgrep -x $PROCESS >/dev/null || return 0; sleep 0.25; done
    pkill -x $PROCESS 2>/dev/null || true
    sleep 1
}

launch_playground() {
    open -b $PLAYGROUND_ID "$@"
    for _ in {1..80}; do
        pid=$(pgrep -x $PROCESS | head -1 || true)
        [[ -n "$pid" ]] && return 0
        sleep 0.25
    done
    bad "Droppy Playground did not start"
}

# The first sample is the average since launch, so it is thrown away for CPU
# and POWER and kept only as the base for the wakeup counter, which is
# cumulative and has to be differenced.
summarise() { awk '
    { gsub(/[+-]$/, "", $2); gsub(/[+-]$/, "", $3); gsub(/[+-]$/, "", $4)
      n++
      if (n == 1) { first = $3; next }
      cpu += $2; power += $4; last = $3; counted++ }
    END {
      if (counted < 1) { print "n/a n/a n/a 0"; exit }
      printf "%.3f %.3f %.3f %d\n", cpu/counted, (last - first)/counted, power/counted, counted
    }' "$1" }

# measure <name> [open arguments...]: relaunch, settle, a minute of top, and
# the droplet's own log lines for the whole run.
measure() {
    local name=$1; shift
    quit_playground
    /usr/bin/log stream --info --style compact \
        --predicate 'subsystem == "app.getdroppy.Droppy" AND category BEGINSWITH "droplet"' \
        > "$scratch/$name.log" 2>/dev/null &
    local logger=$!
    sleep 1
    launch_playground "$@"
    say "$name: settling ($SETTLE s), then sampling $((SAMPLES - 1)) s"
    sleep $SETTLE
    top -pid "$pid" -l $SAMPLES -stats pid,cpu,idlew,power -s 1 2>/dev/null \
        | awk -v pid="$pid" '$1 == pid { print }' > "$scratch/$name.top" || true
    kill $logger 2>/dev/null || true
    wait $logger 2>/dev/null || true
    read -r cpu wakeups power rows <<< "$(summarise "$scratch/$name.top")"
    [[ "$rows" -gt 0 ]] || bad "top produced no samples for the $name run"
    typeset -g "cpu_$name=$cpu" "wakeups_$name=$wakeups" "power_$name=$power"
    typeset -g "started_$name=$(grep -c 'clock started' "$scratch/$name.log" || true)"
    typeset -g "stopped_$name=$(grep -c 'clock stopped' "$scratch/$name.log" || true)"
    typeset -g "seat_$name=$(grep -o 'seat is now [^ ]*' "$scratch/$name.log" | tail -1 | sed 's/seat is now //')"
    typeset -g "loaded_$name=$(grep -c 'Droplet ori-weather .* activated' "$scratch/$name.log" || true)"
}

busy=$(top -l 2 -n 0 -s 1 2>/dev/null | awk -F'[ %]+' '/CPU usage/ {u=$3; s=$5} END {printf "%.0f", u + s}')
if [[ -n "$busy" && "$busy" -gt 25 ]]; then
    machine="the machine was $busy% busy on its own account before the sampling began, so these figures are an upper bound"
else
    machine="the machine was otherwise quiet"
fi

# The user's pin, as hex of the JSON the host stored, or empty if none.
saved_pin=$(defaults export $PLAYGROUND_ID - 2>/dev/null | /usr/bin/python3 -c '
import plistlib, sys
value = plistlib.loads(sys.stdin.buffer.read()).get(sys.argv[1])
print(value.hex() if isinstance(value, bytes) else "")' $PIN_KEY || true)

set_pin() { # set_pin true|false, with the Playground quit
    quit_playground
    defaults write $PLAYGROUND_ID $PIN_KEY -data "$(print -n "$1" | xxd -p)"
}

restore_pin() {
    if [[ -n "$saved_pin" ]]; then
        defaults write $PLAYGROUND_ID $PIN_KEY -data "$saved_pin"
    else
        defaults delete $PLAYGROUND_ID $PIN_KEY 2>/dev/null || true
    fi
}

# --- the three runs -------------------------------------------------------

quit_playground
rm -rf "$FOLDER"
# Whatever happens, the Playground is left with this build installed and
# running, the way make install leaves it.
restore() {
    quit_playground
    restore_pin
    rm -rf "$FOLDER"
    mkdir -p "$FOLDER"
    cp -R .build/OriWeather.droplet "$FOLDER/"
    xattr -dr com.apple.quarantine "$FOLDER" 2>/dev/null || true
    launch_playground
    rm -rf "$scratch"
}
trap restore EXIT

measure removed

mkdir -p "$FOLDER"
cp -R .build/OriWeather.droplet "$FOLDER/"
xattr -dr com.apple.quarantine "$FOLDER" 2>/dev/null || true
set_pin true
measure seated --env OW_DEMO=1
set_pin false
measure unseated --env OW_DEMO=1

# --- the verdict ----------------------------------------------------------

failed=0
verdict() { # verdict <run>: the run against the baseline
    local run=$1
    local w=${(P)${:-wakeups_$run}} c=${(P)${:-cpu_$run}}
    local ok=$(awk -v w="$w" -v b="$wakeups_removed" -v c="$c" -v bc="$cpu_removed" \
        -v nw="$NOISE_WAKEUPS" -v nf="$NOISE_FRACTION" -v nc="$NOISE_CPU" \
        'BEGIN { n = nw; if (b * nf > n) n = b * nf; print (w - b <= n && c - bc <= nc) ? "pass" : "fail" }')
    [[ "$ok" == "fail" ]] && failed=1
    print "$ok"
}

seated_verdict=$(verdict seated)
unseated_verdict=$(verdict unseated)

if [[ "$loaded_seated" -lt 1 || "$loaded_unseated" -lt 1 ]]; then
    failed=1
    load_line="The droplet did not activate in every run with it installed (seated $loaded_seated, unseated $loaded_unseated); the figures are not about it."
else
    load_line="The droplet activated in both runs it was installed for."
fi

# The seated run has to have been seated, or it measured the wrong thing.
if [[ "$seat_seated" != "compact" && "$seat_seated" != "secondary" ]]; then
    failed=1
    load_line="$load_line The seated run was never seated (${seat_seated:-no seat logged}), so it measured nothing."
fi

# Unseated and unshelved, no timer: the droplet logs every clock it starts.
if [[ "$started_unseated" -gt 0 ]]; then
    failed=1
    clock_line="fail: the droplet started its clock $started_unseated time(s) with no seat and no shelf"
else
    clock_line="pass: no clock started in the unseated run (seat ${seat_unseated:-never assigned})"
fi

stamp=$(date '+%Y-%m-%d')
report="docs/energy/$stamp.md"
mkdir -p docs/energy
{
    print "# Energy, $stamp"
    print ""
    print "Droppy Playground $(defaults read '/Applications/Droppy Playground.app/Contents/Info' CFBundleShortVersionString 2>/dev/null),"
    print "$(sw_vers -productName) $(sw_vers -productVersion), the \`$PROCESS\` process only,"
    print "$((SAMPLES - 1)) samples a second apart per run after $SETTLE s to settle, and $machine."
    print "The pointer was not parked; wherever it was, it was there for all three runs."
    print ""
    print "| Run | Idle CPU (%) | Idle wakeups (a second) | POWER | Seat | Clock started | Against removed |"
    print "|---|---|---|---|---|---|---|"
    print "| removed | $cpu_removed | $wakeups_removed | $power_removed | | | baseline |"
    print "| seated (OW_DEMO=1, pinned) | $cpu_seated | $wakeups_seated | $power_seated | ${seat_seated:-none logged} | $started_seated | $seated_verdict |"
    print "| unseated (OW_DEMO=1, unpinned) | $cpu_unseated | $wakeups_unseated | $power_unseated | ${seat_unseated:-none logged} | $started_unseated | $unseated_verdict |"
    print ""
    print "The line: a run with the droplet in it may wake the Playground at most"
    print "max($NOISE_WAKEUPS, ${NOISE_FRACTION} of the baseline) a second more than the removed run, and"
    print "cost at most $NOISE_CPU% more CPU; the unseated run may start no clock."
    print ""
    print "$load_line"
    print "Unseated and unshelved: $clock_line."
} > "$report"

cat "$report"
say "wrote $report"
(( failed )) && bad "the droplet costs the Playground more than D6 allows"
say "the droplet is inside D6"
