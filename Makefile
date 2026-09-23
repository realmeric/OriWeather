# The gate is `make test`: the unit tests, the bundle, the intake's checks,
# and the harness's verdict with every surface drawn to a picture.

# The DroppyKit checkout: `droppykit` on the PATH if there is one, otherwise a
# checkout beside this repository. `make SDK=/path/to/droppykit test` names
# another.
SDK ?= $(abspath $(CURDIR)/../droppykit)
DROPPYKIT := $(or $(shell command -v droppykit 2>/dev/null),$(SDK)/Scripts/droppykit)
export DROPPYKIT

.PHONY: test build validate icon shots offline screenshots install energy clean

# The tests build on SwiftPM's native engine. Swift 6.4's default engine
# codesigns the test bundle, and codesign refuses the Finder info iCloud Drive
# writes on every folder under ~/Documents, where this repository lives.
test:
	swift test --build-system native
	$(DROPPYKIT) build
	$(MAKE) icon
	$(DROPPYKIT) validate
	$(MAKE) offline

build:
	$(DROPPYKIT) build

validate:
	$(DROPPYKIT) validate

# The icon's three layers and the avatar. Deterministic, so a run that
# changed nothing leaves git clean.
icon:
	@mkdir -p .build
	swiftc -parse-as-library -O -o .build/make-icon scripts/make-icon.swift
	.build/make-icon

shots:
	$(DROPPYKIT) run -- --shots ./shots --report ./shots/report.json
	/usr/bin/python3 scripts/check-report.py shots/report.json

# The harness again, with network-client taken away. The harness starts with
# exactly the capabilities the manifest declares and has no flag to deny one,
# so it is handed a copy of the manifest without it (beside droplet.json,
# because assets resolve from the manifest's folder). droppykit run puts its
# own --manifest first, so the app `make shots` built is run directly. The demo
# sky needs no network, so the wing must still carry a temperature.
offline: shots
	/usr/bin/python3 -c 'import json; m = json.load(open("droplet.json")); m["capabilities"] = []; json.dump(m, open(".droplet-offline.json", "w"), indent=2)'
	.build/OriWeatherHarness.app/Contents/MacOS/OriWeatherHarness --manifest "$(CURDIR)/.droplet-offline.json" --shots ./shots/offline --report ./shots/offline/report.json
	rm -f .droplet-offline.json
	/usr/bin/python3 scripts/check-report.py shots/offline/report.json --offline

# The Store's screenshots, cut from the harness. Not part of the gate: they
# are committed, and read by eye when they change.
screenshots:
	scripts/screenshots.sh

install: build
	scripts/install.sh

# What the droplet costs the Playground (D6): three minutes of top against
# the host with the droplet removed, seated, and unseated. Part of the gate
# from OW-16 on, run after make test because it relaunches the Playground.
energy: build
	scripts/energy.sh

clean:
	rm -rf .build shots
