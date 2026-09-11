# The gate is `make test`: the unit tests, the bundle, the intake's checks,
# and the harness's verdict with every surface drawn to a picture.

SDK := $(HOME)/Documents/Projects/apps/droppykit
DROPPYKIT := $(SDK)/Scripts/droppykit

.PHONY: test build validate icon shots offline install energy clean

test:
	swift test
	$(DROPPYKIT) build
	$(MAKE) icon
	$(DROPPYKIT) validate
	$(MAKE) offline

build:
	$(DROPPYKIT) build

validate:
	$(DROPPYKIT) validate

# The icon layer and the avatar, drawn from Marks.swift. Deterministic, so a
# run that changed nothing leaves git clean.
icon:
	@mkdir -p .build
	swiftc -parse-as-library -O -o .build/make-icon scripts/make-icon.swift \
		Sources/OriWeather/Marks.swift Sources/OriWeather/Sky/Weather.swift
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

install: build
	scripts/install.sh

energy:
	@echo "make energy arrives with OW-16."

clean:
	rm -rf .build shots
