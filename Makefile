# The gate is `make test`: the unit tests, the bundle, the intake's checks,
# and the harness's verdict with every surface drawn to a picture.

SDK := $(HOME)/Documents/Projects/apps/droppykit
DROPPYKIT := $(SDK)/Scripts/droppykit

.PHONY: test build validate shots install energy clean

test:
	swift test
	$(DROPPYKIT) build
	$(DROPPYKIT) validate
	$(MAKE) shots

build:
	$(DROPPYKIT) build

validate:
	$(DROPPYKIT) validate

shots:
	$(DROPPYKIT) run -- --shots ./shots --report ./shots/report.json
	/usr/bin/python3 scripts/check-report.py shots/report.json

install: build
	scripts/install.sh

energy:
	@echo "make energy arrives with OW-16."

clean:
	rm -rf .build shots
