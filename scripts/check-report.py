#!/usr/bin/python3
"""The harness's verdict, read the way the gate reads it.

Green means `problems` is empty, activation did not throw, and every surface
droplet.json declares came back `provided`.
"""

import json
import sys

arguments = [a for a in sys.argv[1:] if not a.startswith("--")]
offline = "--offline" in sys.argv
path = arguments[0] if arguments else "shots/report.json"
report = json.load(open(path))
failures = []

for problem in report.get("problems", []):
    failures.append("problem: %s" % problem)

error = (report.get("activation") or {}).get("error")
if error:
    failures.append("activate(host:) threw: %s" % error)

for surface in report.get("surfaces", []):
    if surface.get("declared") and surface.get("verdict") != "provided":
        failures.append("%s is declared and %s" % (surface["surface"], surface.get("verdict")))
    if surface.get("implemented") and not surface.get("declared"):
        failures.append("%s is implemented and not declared" % surface["surface"])

if offline:
    # The run with network-client taken away: nothing granted, and the demo
    # sky still on the wing.
    if (report.get("capabilities") or {}).get("granted"):
        failures.append("the offline run was granted %s" % report["capabilities"]["granted"])
    if not (report.get("liveActivity") or {}).get("publishing"):
        failures.append("with network-client off the wing carries nothing")

if failures:
    print("\n".join(failures))
    sys.exit(1)

provided = [s["surface"] for s in report.get("surfaces", []) if s.get("verdict") == "provided"]
print("Report%s: no problems, provided %s" % (" (offline)" if offline else "", ", ".join(provided)))
