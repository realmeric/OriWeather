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

## OW-3, the geocoder (2026-09-11)

The answer in `GeocoderTests` was taken from
`https://geocoding-api.open-meteo.com/v1/search?name=Istanbul&count=5&language=en&format=json`
on 2026-09-11 and is kept whole. Its first result is Istanbul, `admin1`
Istanbul, `country` "Republic of Türkiye" (not "Turkey"), `timezone`
Europe/Istanbul, at 41.01384, 28.94966. A name nobody has heard of comes back
as `{"generationtime_ms":…}` with no `results` key at all rather than an empty
array, which is why the reader treats a missing key as an empty list.

The reader keeps six fields and drops the rest (`population`, `postcodes`,
`elevation`, the ids). The coordinate is rounded inside `City.init`, so a city
never holds more than two decimals, whichever way it was made.

## OW-6, the wing (2026-09-11)

The harness awards the compact seat only after a state has been published,
and Droppy does the same: no state, no seat. The clock runs only while
seated, so a droplet that waited for a seat before reading would never read.
Activation therefore reads once (`WeatherModel.Reason.launch`, gated by the
interval like a seat) so there is something to publish; from then on the host
decides the seat and the seat decides the clock.

What the Playground did with `OW_DEMO=1` and "Keep on the notch" off: within
a quarter of a second of activation the seat went to `none(surface-suppressed)`
and then `compact`, and the clock started. So with pinning off the host still
reports the compact seat at rest; the hover-only reveal is how the row is
drawn, not a seat the droplet is told about. D6 holds as written (the clock
runs while seated), which in practice means the clock runs at rest on a free
notch whether or not the row is pinned. The Playground's window was not given
to this session, so the hover, the pin and the music box on OW-6 wait for eyes.

The droplet's own lines land under `category == "droplet"` (singular), tagged
`[ori-weather]`, and at the info level, so `log show` needs `--info` to see
them; the loader's lines are under `droplets`. Seat changes are logged at info
for that reason.

The harness does not draw the companion pill at all (nothing under
`DroppyKitHarness` calls `makeCompanionCompact` or `makeCompanionDetail`), so
the puck is drawn by a test instead (OW-8).
