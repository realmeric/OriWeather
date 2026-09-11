# Notes

What the machine and the SDK turned out to say, card by card. The board says
what to do; this says what was found doing it.

## OW-1, the scaffold (2026-09-11)

The build engine. `droppykit build` on Swift 6.3.3 (Xcode 26.6) used SwiftPM's
native engine, which `droppykit version` reports as the toolchain's default.
The native engine writes no `OriWeather.o`, only `OriWeather.build/*.o`, and
1.2.1's build script is the first that finds those; 1.2.0 would have stopped
with "no compiled objects". A clean build takes about 36 seconds, most of it
DroppyKit built resiliently once.

Where the bundle landed. `.build/OriWeather.droplet`, universal (`x86_64
arm64`), linking `DroppyKit.framework` with no direct-access imports. `make
install` copies it to `~/Library/Application Support/Droppy
Playground/Droplets/ori-weather/OriWeather.droplet`, which the first install
created.

What the Playground said. Droppy Playground 1.0.9 (standing in for Droppy
15.3.0) had the bundle mapped two seconds after relaunch, and its log, under
`subsystem == "app.getdroppy.Droppy" AND category == "droplets"`, read
"Droplet ori-weather 1.0.0 activated" and "Droplets: 1 running of 1
installed", with no refusal. The Store row itself was not read from this
session; the log line is the loader's verdict it would have shown.

One thing the scaffold does not do: it does not validate as written. Its
`droplet.json` carries `source.commit: ""`, and `droppykit validate` refuses
a community droplet without one ("A community droplet must declare
source.repository, source.commit and source.license."). The manifest now names
`https://github.com/realmeric/OriWeather` (D2) and carries `"unpinned"` as the
commit, which the validator accepts because it only asks for something; OW-18
replaces it with the submitted hash. `droppykit submit` reads the commit from
HEAD, not from the manifest, so the placeholder cannot be what gets submitted.

The MCP wiring does name the package folder: both `.mcp.json` files said
`--package .../ori-weather` after the scaffold, so the move to `OriWeather`
was followed by `droppykit agent`, which rewrote both and left `AGENTS.md` and
`CLAUDE.md` alone.
