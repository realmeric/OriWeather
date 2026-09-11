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

## OW-12, the room (2026-09-11)

The SDK has no text-field row. The city row is a `DropletStackedRow` with a
plain `TextField` in it, filled with `AdaptiveColors.overlayAuto` at
`DroppyOpacity.light` inside a `DroppyRadius.small` continuous rectangle,
because the guidelines forbid outlines and `.roundedBorder` is one. It is the
one place the room goes off the components.

The harness's sidebar search filters the harness's own page titles and does
not read `settingsSearchEntries`, so "the harness's search finds Keep on the
notch" is checked by `RoomTests` against the entries instead; in Droppy those
entries feed the Settings search.

The harness does not see URLSession, so a geocoder request cannot appear on
its Activity page by itself. Each request is logged ("asked the geocoder for
…"), which the Activity page does show, and `RoomTests` counts them: eight
keystrokes 30 ms apart are one request, and choosing a match is none, because
the match carries its coordinate. The shots never type, so the shot of the
room has no matches in it.

## OW-13, the unit (2026-09-11)

One reading, in Celsius, converted at draw time. `degrees(in:)` rounds after
converting, so 25.5 °C is 77.9 °F and reads 78°; rounding to 26° first would
say 79°. The figure goes through `Int`, so anything that rounds to zero from
below reads "0°": -0.4 °C, and -18 °C, which is -0.4 °F. The card's "in both"
is those two, one in each unit; -0.4 °C itself is 31° in Fahrenheit.

The city's time zone, kept since OW-3, is deliberately not what `Ago` is
measured in: an age is a duration between two instants and has no zone. The
zone is what a future hourly row would be labelled in (the Wishlist's second
item), and nothing reads it yet.

## OW-17, what review sends back and what answered it (2026-09-11)

`Submitting.md` lists the five reasons review sends a droplet back, most often
first. Each has a card.

Capabilities you do not use. The manifest asks for `network-client`, and
since the shortcut `global-shortcuts`, each for one use: the weather and the
geocoder, and the one shortcut. Nothing is read without the first (OW-6): the droplet checks the
grant at activation and, refused, reads nothing rather than trying. The one
thing that might have wanted more, where the Mac is, was answered by not
asking (D4, OW-3).

Design that ignores the surface. Every number and colour of the droplet's own
is in `Look.swift`, and `LookTests` fails on one anywhere else (OW-5); the
wing, the card and the shelf use Droppy's metrics and white ladder (OW-6, OW-7,
OW-11), and the room is built from the settings components, with the one
exception written down under OW-12.

Work that does not stop. `deactivate()` stops the clock, cancels every
subscription and the city search, and publishes nil, and `DropletTests` checks
that nothing is fetched afterwards (OW-6). The clock runs only while seated or
shelved (OW-11), and `make energy` checks from the host's side that an
unseated droplet starts none (OW-16).

A live activity that never yields. No city or no reading publishes nil, never
an empty wing (OW-6), and clearing the city yields the seat at once (OW-9).

An icon that does not read at 28 pt. The 28 pt render is kept in `shots/` and
read before the icon was accepted (OW-15).

`kit.minAPI` is 1.1.0: the card's `cardContentHeight` and the compact
padding arrived in 1.1.0, and nothing newer is called; 1.2.0 and 1.2.1
changed no API.

## After OW-17: the pin, and the country (2026-09-11)

"Keep on the notch" did nothing in the Playground: on or off, the weather sat
on the wings at rest. That is what the log showed on OW-6 (the compact seat at
rest with pinning off), seen by eye. The Playground, standing in for Droppy
15.3, seats a droplet's published state whether or not
`joinsPersistentActivitySet` is set, so the flag cannot carry the pin. The
droplet keeps the pin itself now: off, it publishes nil and yields the seat,
and the weather lives on the shelf; on, it publishes with the flag set. The pin
is still off until the user turns it on (D5), except under the demo sky, which
exists to show the wing. Unpinned and unshelved the clock stops, so off is also
cheaper.

The geocoder answers "Republic of Türkiye" for TR, where it answers "Germany"
and "United Kingdom" for DE and GB. The country is now the English name macOS
gives the result's `country_code` ("Türkiye"), and the geocoder's own name only
when there is no code. A city chosen before this keeps the name it was stored
with until it is chosen again.

## After OW-17: cities, the automatic city, the shortcut (2026-09-11)

The geocoder's answer mixes places people live in with places that are not
towns: for "Istanbul" it answered the city, a village, two airports and the
old town. Each result carries a GeoNames `feature_code`, and the reader now
keeps populated places (`PPL` and its kinds, a capital, a seat of government)
and drops sections of towns (`PPLX`) and places historical, abandoned or
destroyed. Ten are asked for so that five are usually left.

The automatic city reads the Mac's time zone, which macOS sets from the Mac's
location when "Set time zone automatically" is on, and geocodes the city it is
named after, preferring the match in that zone (Paris, Europe/Paris, not
Paris, Texas). It is found at activation and when the system says the zone
changed, and asks nothing while the stored city is already in the zone. It is
on until somebody names a city and never switches itself on over one that was
chosen, so Meric's Kaunas stays Kaunas. A zone that names no city ("UTC") finds
nothing and says so in the log. IP geolocation was the other way and was left
out: a third company would see the address, and behind a VPN it names the
VPN's city.

The shortcut needs `global-shortcuts`, the second capability; it is used for
exactly one thing, the pin, and the room shows it only when granted. The host
takes the Control-Option-W suggestion only if nothing else has it, and the user
rebinds it in Droppy's Settings, Shortcuts.

Droppy's Store has three categories, Productivity, Media and AI, read from
getdroppy.app/droplets, and Droppy's own Weather droplet is in Productivity,
so that is where this one is.

`make energy` now writes the pin into the Playground's preferences for each
run (the host stores it as JSON data under `droplet.ori-weather.pinned`) and
puts the user's value back afterwards; both runs use the demo sky, so the
unseated run has a reading and holds no seat, which is the case D6 is about.

## Seen in the Playground (2026-09-11)

With the Playground's window given to the session, on the build of `c05350b`:
with "Keep on the notch" off the notch carried nothing; turned on, the leading
wing showed the sun and the trailing one 17° for Kaunas within a second, and
the log said `seat is now compact` and `clock started (seat)`; turned off
again, the wings cleared. The room rendered in the Store row's page with the
automatic toggle, the city, the unit and interval pickers, the pin and the
shortcut bound as ⌃⌥W. Typing "Istanbul" logged one geocoder request and
listed Istanbul and İstanbulboğazı, Ordu, both "Türkiye", no airports. The
Store row's page showed both screenshots and the two capabilities in words,
"Connect to the internet" and "Use keyboard shortcuts".

Not seen: the shelf and the hover card, which open only when the pointer is on
the notch, and music taking the seat. Those need the screen, not the window.

## After OW-17: the shortcut that ate W, and a better where (2026-09-11)

The shortcut bound a bare W in the Playground: every W typed anywhere on the
Mac went to the droplet and flipped the pin, and no W reached the app it was
typed into. `DropletKeyboardShortcut.modifiers` is documented as a
"Carbon-style modifier mask", and the suggestion carried Carbon's control and
option bits (1 << 12 and 1 << 11). The host read them as no modifiers. The
field is a `UInt`, as `NSEvent.ModifierFlags` is, and the suggestion now
carries AppKit's control and option flags. The host keeps no binding on disk
(nothing under the Playground's defaults or its folder named the shortcut), so
nothing stale survives a relaunch. The handler also refuses any press that
does not hold the binding's modifiers, and a binding with none at all, so a
host that misreads a mask again costs a key and never the pin.

The time zone could not tell Ankara from Istanbul. The automatic city now asks
GeoJS (get.geojs.io, free, keyless, HTTPS, and it says it stores nothing) which
city the Mac's internet address is in, keeps the town, the region, the
country, a two-decimal coordinate and the zone, and drops the address and the
network's name. The answer is used when its zone is the Mac's; otherwise it is
a VPN, and the zone's own city is used, as before. It is looked up at start
when there is no city, and otherwise only when the Mac may have moved (a new
network, a wake, a new zone) and somebody can see the weather, never twice in
ten minutes unless the zone changed. The same town again writes nothing, so
the weather is not read twice for a place the Mac never left. Of the four
keyless services tried from here (ipwho.is, ipapi.co, ipinfo.io, GeoJS), all
four said Istanbul.

Checked on the real screen after the fix, with the Playground in front: a bare
W typed "w" into its search field and left the wings alone, and Control-Option-W
took the weather off the wings and put it back, with nothing typed. A
synthetic press from the shell proved nothing, because the shell may not post
key events (`CGPreflightPostEventAccess()` is false), so the keys were pressed
through the screen. `make energy` after the network and wake observers went in:
2.02 wakeups a second without the droplet, 1.78 seated, 2.03 unseated.

The shortcut is Control-Option-Command-W since Meric asked for it. Pressed on
the real screen with the Playground in front: W typed "w", Control-Option-W
now does nothing, and Control-Option-Command-W took the weather off the wings
and put it back.
