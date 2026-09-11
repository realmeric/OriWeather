# Ori Weather kanban

A weather droplet for Droppy, drawn the way OriNotch draws the weather. Since 2026-09-08 Droppy is the notch Meric uses every day (OriNotch D24), and OriNotch's weather is the one surface of his he misses on it: a mark and a temperature on the wing when nothing else wants the notch, a small card behind it, the last reading kept and dated when the network goes. DroppyKit, released 2026-09-11, lets a third party draw on Droppy's own wings, so this repo puts that surface on the notch he actually looks at instead of the one he built. It is a guest in Droppy's process, not a product: it links DroppyKit 1.2.1 as a resilient framework, declares `network-client` and nothing else, and is reviewed, built and signed by Droppy before Droppy will load it.

Written 2026-09-11 against an empty directory, from the SDK's own sources rather than its website: `Sources/DroppyKit/Documentation.docc/` is the text the site is generated from, and `COMPATIBILITY.md`, `HostSupport.md` and `Submitting.md` are the three files every card here leans on. What was read is the SDK; what is typed is this repo's own, with six shapes, a code table and a reader carried over from OriNotch because they are Meric's.

Ori is a family. OriNotch is the parent, where the marks, the words and the behaviour were first drawn, and the droplets that carry them onto Droppy are its children, each named with the prefix; Ori Weather is the first. The droplets do not compete with Droppy, they are made for it: they draw on Droppy's own surfaces, through its SDK, and are reviewed and signed by it. The SDK licence's section 3 says a droplet is its maker's, so this repo picks its own licence and the SDK claims nothing over it. Code travels from the parent into a child as that child's own files, with their tests, and the SDK checkout is opened from the droplet repositories, which are where DroppyKit is written against.

What this machine has, checked 2026-09-11: Droppy 15.2.2-beta.1 (build 15220001), which is below the 15.3 every droplet declares as `minAppVersion`, so it loads nothing from this repo until it is updated; Droppy Playground 1.0.9 in `/Applications`, which stands in for Droppy 15.3.0 and is the only host that loads an unsigned bundle; DroppyKit at tag v1.2.1 on GitLab, not yet cloned, and no `droppykit` on the PATH; Xcode 26.6, Swift 6.3.3 (the 1.2.1 ledger says its build finds SwiftPM's objects on 6.3's engine, which 1.2.0 did not); macOS 26.6.2 with a hardware notch. No Developer ID, which does not matter here: Droppy signs what it accepts. `~/Library/Application Support/Droppy/Droplets/` does not exist yet and `Droppy Playground/Droplets/` does not either; the first install creates the second.

How to work the board: one card at a time, top of Ready first. Read the card, the `docs/notes.md` sections and the `docs/look.md` surfaces it names, do it, run the gate, commit, move the card under Done with its hash. A card is done when every box under Accept is ticked and the gate is green. The gate is `make test`: `swift test`, then `droppykit build`, then `droppykit validate`, then `droppykit run -- --shots ./shots --report ./shots/report.json` with an empty `problems` array and every declared surface `provided`. `make energy` (OW-16) is the second half of the gate from the card that writes it onward. Two boxes belong to every card that draws or runs anything and are not written out each time: the budget holds (D6) and the look matches (D3: OriNotch's `WeatherWing` and `WeatherCard` in composition, Droppy's metrics in size, the shots read after every visual change because there is no window to see). Something you notice on the way becomes a one-line entry under Backlog, not a change. The SDK is read before an API is guessed at; the guides are on disk in the checkout.

Legend. Priority: P0 nothing loads or nothing shows without it, P1 a lie on screen or a missing piece of the feature, P2 robustness or a visible rough edge, P3 hygiene. Effort: S under half an hour, M under two hours, L half a day, XL a day or more. `manual` means the Playground and eyes on the screen; those cards commit only what they had to fix. `research` means the card ends in a note, not code, when the host turns out not to allow the thing.

## Decisions for Meric

Each is written with the recommended option as the default. Strike the other or say so before the card is taken.

- D1, the name. Display name "OriWeather", one word like its parent OriNotch (it was "Ori Weather" until the week it was submitted), droplet id `ori-weather`, Swift product `OriWeather`, bundle identifier `app.getdroppy.droplet.ori-weather` (generated, never typed), preferences under `droplet.ori-weather.*`. The hyphen is what makes the scaffold spell the product `OriWeather` rather than `Oriweather`. The `Ori` prefix is the family's, which every droplet of it carries. The maker is "Ori by realmeric": the family first, and the unique GitHub account beside it, which a copycat calling itself Ori cannot claim. Nothing in the name suggests Droppy publishes it, which the SDK licence's section 6 requires.
- D2, where it lives. `~/Documents/Projects/apps/OriWeather`, its own git repository, public on GitHub as `realmeric/OriWeather` from the card that submits it, because intake refuses a submission without a public repository. The SDK is cloned once to `~/Documents/Projects/apps/droppykit` at v1.2.1 and moved only by `droppykit update`; the scaffold's `.mcp.json` and `AGENTS.md` carry that absolute path. Nothing links OriNotch and nothing imports it: `WeatherReading`, `WeatherCode`, `Place`, `OpenMeteo`, `Ago` and the six weather shapes are copied in as this repo's own files with their tests, and everything else is written against DroppyKit.
- D3, whose design. Composition, marks, words and behaviour are OriNotch's: the six shapes (`Sun`, `Cloud`, `Rain`, `Snow`, `Fog`, `Bolt`) with their tints, the WMO code table in its own words, the degrees rounded to a whole number with the sign, the last reading kept and dimmed to 55% with "2 h ago" in place of the condition. Sizes and colours of text are Droppy's tokens: `DroppyLiveActivityMetrics.iconSize` (13) where OriNotch drew 14, `labelFontSize` (12) where it drew 11, the white ladder `notchSurfacePrimaryText` / `SecondaryText` / `TertiaryText` where OriNotch had its own opacities, `DroppySpacing` for gaps, no padding of this repo's own on a compact accessory because the host insets the wing by `symmetricPadding` already. A point of difference in a glyph is invisible; a droplet that carries its own numbers is the first thing review sends back. One concession the host forces: it draws two wings, so the mark goes on the leading wing and the degrees on the trailing one. OriNotch put both on the right only because its left wing was busy with artwork. The typeface stays plain SF as OriNotch draws it, not Droppy's rounded digits; nothing in the guidelines names a face. The tints live in one file, `Look.swift`; if review sends the marks back for colour, one edit drops them to the ladder and the board says so under Backlog.
- D4, where. A city, not a location. DroppyKit has no location capability (`DropletPermission.known` runs from `notch-surface` to `global-shortcuts` and location is not in it), and review diffs the symbols a bundle links against the capabilities it declares, so CoreLocation in this bundle is a symbol with nothing to declare it under. The city is typed in the settings pane and resolved by Open-Meteo's geocoder, no key, no account, and its coordinate is rounded to two decimals before it goes anywhere, as OriNotch's is. The alternative, `CLLocationManager` in Droppy's process riding Droppy's own `NSLocationWhenInUseUsageDescription`, works on this Mac and is struck: it is the thing the review exists to catch. Added after OW-17 at Meric's request: until a city is named, the city is the one the Mac's time zone is named after, found again when the zone changes; no permission, no third party, one city per zone.
- D5, the seat. `LiveActivityState.priority` 10, OriNotch's `ambient`: among droplets the lowest honest number, and against Droppy's own activities the number does not matter because a droplet holds the compact seat only when none of them want the notch. `joinsPersistentActivitySet` comes from the preference "Keep on the notch", off by default because the SDK says pinning is a strong claim on somebody else's notch and to let the user turn it on; Meric turns it on. The Playground turned out to seat a droplet's state at rest whether or not it joins the persistent set, so the droplet keeps the pin itself: off, it publishes nothing and the weather lives on the shelf (docs/notes.md, "After OW-17"). The state is `nil` while there is no city or no reading: a wing with nothing on it is the one thing the seat rules forbid.
- D6, the budget. OriNotch's D16 scaled to a guest. The clock runs only while the activity is seated (`.compact` or `.secondary`) or the widget is on a shelf (`installState.state.activeWidgetIDs` contains it); unseated and unshelved, no timer, no request, and the last reading stays. One fetch per interval, 30 minutes by default, and one on gaining a seat or a shelf if the reading is older than the interval; ten display wakes in a minute are zero fetches. Nothing rebuilds while `context.presentation.isPresentationSettled` is false. `make energy` against the Playground shows no added idle wakeups and no timer while unseated. Off means off: a disabled droplet has had `deactivate()` called and holds nothing.
- D7, the licence. MIT, the licence the SDK's example declares and the one review reads fastest. `source.license` in the manifest says `MIT` and `LICENSE` in the repo says the rest.
- D8, where it runs until then. Droppy loads only bundles the Store review signed with Droppy's own identity, and the installed Droppy is 15.2.2 besides. So from OW-1 to OW-18 the droplet runs in the harness and in Droppy Playground, and daily use in Droppy itself begins with OW-19, after acceptance, when a signed bundle is placed under `~/Library/Application Support/Droppy/Droplets/ori-weather/`. The board does not pretend otherwise. Two notch apps do not share one notch, so the Playground and OriNotch are never run at once; a look pass is two screenshots side by side.
- D9, what the eyes are. There is no window to look at from the session, so the harness shots are read after every visual card: `live-activity.png`, `shelf-widget.png`, `settings-pane.png`, `overview.png`, `capabilities.png`, `activity.png`, and `report.json` beside them. The Playground is the last mile of every phase, because the harness renders every surface at Droppy's metrics but does not arbitrate the seat, and only a host can show a droplet standing down.

## Done

#### OW-1 · The scaffold

P0 · M · setup

Done in `933baa3`. The scaffold needed `source.commit` filled before it validated (docs/notes.md). The Store row was read through the loader's log line, "Droplet ori-weather 1.0.0 activated", because the session was not given the Playground's window.

Clone `https://gitlab.com/droppyformac1/droppykit.git` at tag v1.2.1 to `~/Documents/Projects/apps/droppykit`, put its `Scripts` on the PATH for the session, and in `~/Documents/Projects/apps` run `droppykit new ori-weather --name "Ori Weather"`, which writes a package that builds, a manifest that validates, a starter icon document, a placeholder avatar and, at the end, `droppykit agent`'s brief. Move the folder to `OriWeather` (the MCP wiring names the SDK's `Scripts`, not this folder, so the move costs nothing; check both `.mcp.json` files anyway). `git init`, the SDK's `.gitignore` plus `shots/`. A `Makefile` with `test` (the gate as the top of the board describes it), `build`, `shots`, `install` (copy `.build/OriWeather.droplet` to `~/Library/Application Support/Droppy Playground/Droplets/ori-weather/`, quit and relaunch the Playground, which is what the MCP `droppykit_install` tool does), `energy` (a placeholder that says OW-16 until then) and `clean`. `docs/notes.md` opened with the three facts this card learns on the machine (which build engine `droppykit build` chose, where the bundle landed, what the Playground's Store row said). `AGENTS.md` keeps the SDK's brief and gains one paragraph under it pointing at this board and the Ori family. A first test that asserts `OriWeatherDroplet.id == "ori-weather"`.

Accept:

- [x] `droppykit build` writes `.build/OriWeather.droplet`, universal, and `droppykit validate` says "Ready to submit." on the scaffold before anything is replaced.
- [x] `make test` is green end to end, and `shots/report.json` has an empty `problems` array with the scaffold's one surface `provided`.
- [x] `make install` puts the bundle in the Playground and its Store row's subtitle is the loader's word for loaded; `log stream --predicate 'subsystem == "app.getdroppy.Droppy" AND category == "droplets"'` shows the load and no refusal.
- [x] Renaming the folder broke nothing: `droppykit version` names the checkout and the pinned tag from inside `OriWeather`.

Commit: `A droplet that loads and says nothing yet`

#### OW-2 · The reading, carried over

P0 · S · model

Done in `ba31acf`.

`WeatherReading`, `WeatherCode` with its marks and words, `Place` with its two-decimal rounding, `WeatherFetching`, `OpenMeteo` with `url(for:)` and `reading(from:now:)`, `WeatherError` and `Ago`, copied from OriNotch's `Weather.swift` and `Notices.swift` as this repo's own files under `Sources/OriWeather/Sky/`, with `OpenMeteoTests` beside them: the recorded body from 2026-09-08 kept inline so no test reaches the network, the local wall clock with the offset beside it (14:00 in Istanbul is 11:00 UTC), the coordinate rounded before it is sent, the code table saying what to draw. Nothing in these files imports DroppyKit.

Accept:

- [x] The five OpenMeteo tests pass unchanged in wording: the current block is read, the time is local with the offset beside it, an empty body is unreadable, the coordinate leaves as `41.01` and `28.95`, and 0 is sun, 48 fog, 65 rain, 75 snow, 95 storm.
- [x] `grep -L DroppyKit Sources/OriWeather/Sky/*.swift` lists every file in the folder.

Commit: `Read the sky the way OriNotch reads it`

#### OW-3 · A city, not a location

P0 · M · model

Done in `0b5a779`.

`City` (name, region, country, `Place`, time zone identifier), `Geocoding` as a protocol, and `OpenMeteoGeocoder` against `https://geocoding-api.open-meteo.com/v1/search` with `name`, `count=5`, `language=en` and `format=json`: the answer's `results` carry `name`, `admin1`, `country`, `latitude`, `longitude` and `timezone`, and the reader keeps those and nothing else. The chosen city is stored under the preference key `city` as JSON through `DropletPreferencesService`, which is `Codable` in and out. A recorded answer for "Istanbul" is kept inline in `GeocoderTests` the way the forecast body is, taken when the card is built and dated in `docs/notes.md`.

Accept:

- [x] The recorded answer decodes to five cities with the first one's coordinate already rounded to two decimals, and a body with no `results` decodes to an empty list rather than an error, because a city nobody has heard of is not a failure.
- [x] `OpenMeteoGeocoder.url(for: "İstanbul")` percent-encodes the name and the host is `geocoding-api.open-meteo.com`.
- [x] A `City` written to a `HarnessPreferencesService` reads back equal; the harness services are public and are this repo's fakes.

Commit: `Ask Open-Meteo where a city is instead of asking macOS where the Mac is`

#### OW-4 · The model

P0 · M · model

Done in `83767dc`.

`WeatherModel`, OriNotch's shape without its location half: a fetcher, a city, a clock, `reading`, `isStale`, and `now` published on every attempt and never between them, so an old reading's age is right when it is drawn and no clock ticks for a figure that changes twice an hour (D6). `every` from the preference `intervalMinutes` (15, 30 or 60, default 30) times 60. `start()` registers the clock and refreshes at once, `stop()` invalidates it, `isRunning` says which, and `refresh(at:)` is what a seat or a shelf calls with a reason. A refused read leaves the last reading up and sets `isStale`; nothing was ever read is `nil`, not stale. The model knows nothing about seats or widgets: OW-6 and OW-11 decide when to start it.

Accept:

- [x] `WeatherModelTests`: it reads and puts a temperature up; a refused read leaves the last one up and dimmed; off costs nothing (a model built and never started has called nothing, with an actor counting the fetcher's calls); the clock lives as long as the feature does; with no city nothing is fetched.
- [x] `refresh(at:)` with a `now` inside the interval of the last successful reading is a no-op, asserted with a fixed date and the counting fetcher.

Commit: `A model that reads on a clock it can put down`

#### OW-5 · The marks and the look

P1 · M · look

Done in `a4f1015`.

`Marks.swift`: the six shapes from OriNotch's `Glyphs.swift`, `Sun`, `Cloud`, `Rain`, `Snow`, `Fog` and `Bolt`, as this repo's own `Shape`s. `Look.swift`: every number and colour of this repo's own in one place, which is the tints (the sun and the bolt in a warm yellow, rain in a blue, snow in the primary white, fog in the tertiary white, cloud in the secondary), the stale opacity 0.55, and the card glyph size 20 that the host has no token for. Everything else a view needs comes from `DroppyLiveActivityMetrics`, `DroppySpacing`, `DroppyRadius` and `AdaptiveColors`. `WeatherMark(code:isDay:)` picks the shape and the tint; by night the sun is drawn in the secondary white, as OriNotch draws it. `docs/look.md` opened with the two surfaces described from OriNotch's `WeatherView.swift`, in this repo's words.

Accept:

- [x] `Look.swift` is the only file under `Sources/OriWeather/` with a literal `Color(` or a literal point size in it; a grep in the test target asserts it, which is how OriNotch keeps a number in a view a smell.
- [x] `MarksTests` renders each shape into a 16 by 16 path and asserts it is non-empty and inside its rect; a shape that leaks past its rect at 13 pt is the kind of thing a wing clips without a word.

Commit: `Six marks and one file that says what colour they are`

#### OW-6 · The temperature on the wing

P0 · L · wing

Done in `c01c15f`. The pin half of the fifth box was seen after OW-17 (docs/notes.md, "Seen in the Playground"): off, nothing on the wings; on, the mark and the degrees. The music half still waits for eyes on the Playground: its window was not given to this session. What the log said instead is in docs/notes.md under OW-6, and it is not what D5 expected: with pinning off the Playground still reports the compact seat at rest.

`OriWeatherDroplet` conforms to `LiveActivityProviding` and the manifest lists `live-activity` under `surfaces` and `network-client` under `capabilities`, and nothing else in either. `liveActivityState` is a `CurrentValueSubject<LiveActivityState?, Never>` fed from the model: `nil` with no city or no reading; otherwise priority 10, the accessibility title "26 degrees, partly cloudy, Istanbul", `isInteractive: false`, `joinsPersistentActivitySet` from the preference `pinned` (default false), and `expandedWidgetID: "weather"` so a tap on the pill opens OW-11's widget once it exists. `makeCompactLeading()` is the mark at `iconSize`; `makeCompactTrailing()` is the degrees at `labelFontSize`, medium, plain SF, `monospacedDigit()`, in `notchSurfacePrimaryText`; neither adds padding of its own. `liveActivitySeatDidChange` is where the clock lives: seated, `model.start()`; `.none`, `model.stop()`, unless OW-11's widget is on a shelf. `activate(host:)` reads the city and the preferences and subscribes to `preferences.didChange` so a new city refetches and a flipped pin republishes; `deactivate()` stops the clock, cancels every subscription and drops the host.

Accept:

- [x] `live-activity.png` shows the mark in the leading wing and "26°" in the trailing one on the notch shape, and the same pair inside the island, with the row 37 pt tall and nothing of this repo's between the host's insets and the glyph.
- [x] `-12°` fits the trailing wing on the notch without clipping; if it does not, the shot says so and the card drops the sign's thin space rather than the mark.
- [x] `DropletTests` build a `DropletHost` from the harness services: after `activate` with a city and a fake fetcher the subject carries a state with priority 10; with no city it carries `nil`; `liveActivitySeatDidChange(.none(.outranked))` leaves `model.isRunning` false and `.compact` turns it true; after `deactivate` the subject is `nil`, `isRunning` is false and the fetcher's count stops moving.
- [x] `overview.png`'s verdict pill for the live activity says provided, and `capabilities.png` shows one switch.
- [ ] In the Playground with `pinned` off the row appears while the pointer rests on the closed notch and goes when it leaves; with `pinned` on it stays at rest, and starting music in the Playground's player takes the seat and the log says `surface-suppressed`.

Commit: `Put the temperature on the wing when nothing else wants it`

#### OW-7 · The card behind the wing

P1 · M · wing

Done in `9935670`. The stale shot is `shots/stale/live-activity.png`, taken with `OW_DEMO=stale droppykit run -- --shots ./shots/stale`.

`makeExpanded(context:)`, the card the compact row grows into on hover, `context.availableWidth` by `cardContentHeight` (59) and not a point taller, because a taller view is clipped without a word. Left, the mark at `Look.cardMark` (20); then the degrees large (20, semibold, monospaced digits, primary) with the condition under them in the tertiary white; right, the city in the secondary white and under it "Feels like 24°", or, when the reading is stale, `Ago.words` in place of the condition and the whole card at `Look.staleOpacity`. Nothing avoids the camera housing: the host has already inset the card below it.

Accept:

- [x] The expanded shot at both shapes shows the four texts and the mark, none clipped, the degrees and the feels-like agreeing with the recorded body (26° and 24°).
- [x] `OW_DEMO=stale` (OW-14) puts "2 h ago" where "Partly cloudy" was and dims the card, in the shot.

Commit: `Grow the wing into a card on hover`

#### OW-8 · The puck and the pair

P2 · S · wing

Done in `27fd488`. The harness draws no companion pill, so the first box was met by `CompanionTests`, which draws the puck and the capsule into `shots/extra/`. The second waits for eyes on the Playground.

When another activity owns the compact seat and this one rides the companion pill, `makeCompanionCompact(context:)` draws the mark alone, sized to `context.slotSize` rather than to `iconSize`, because the default reuses the leading accessory at wing scale and a 13 pt sun in a 24 pt puck is a dot. `makeCompanionDetail(context:)` is one line, "26° Partly cloudy", leading-aligned beside the mark when the pill grows into its capsule.

Accept:

- [x] The harness's secondary-seat rendering shows the mark filling the puck and the one-line detail in the grown capsule.
- [ ] In the Playground, with the media player playing, the pill carries the mark and hovering it reads the line.

Commit: `Fit the mark into the puck`

#### OW-9 · Stale, away and back

P1 · M · wing

Done in `c758dbc`.

The behaviour OriNotch's ORI-36 and ORI-61 settled, made true under a host that seats and unseats: the interval is the only clock, so ten display wakes in a minute are zero fetches; losing the seat stops the clock and keeps the reading; regaining it refreshes only if the reading is older than the interval; a refused refresh dims and dates rather than clears; `now` moves on every attempt so the age on screen is measured against the last attempt and never against a ticking clock. `host.liveActivity.yield(reason: .idle)` is called when the city is cleared, so the seat is given up before the publisher catches up.

Accept:

- [x] `StaleTests` drive the model with fixed dates: seat lost at 14:00, regained at 14:10 fetches nothing, regained at 14:45 fetches once; a wake storm of ten `refresh(at:)` calls inside a minute is one request at most.
- [x] Clearing the city calls `yield(reason: .idle)` on the harness live activity service exactly once, asserted from its recorder.

Commit: `Keep the last reading and say how old it is`

#### OW-11 · The card on the shelf

P1 · L · shelf

Done in `b22b620`. The harness pairs the widget with a second copy of itself, not with a widget of its own, so the paired shot is two weathers side by side. The Playground box waits for eyes.

`ShelfWidgetProviding` with one descriptor, id `weather`, title "Weather", `systemImage` a symbol name because the descriptor takes one and the grid draws it, `preferredSoloWidth` and `preferredPairedWidth` both declared (the host refuses a descriptor missing either), `contentHeight: .fixed`, and `searchKeywords`. Solo, `context.isCompact` false: the mark, the degrees, the condition, the city, feels like, and the age of the reading on one line at the bottom in the tertiary white. Paired: the mark and the degrees, and the condition if `context.availableSize` has room for one more line, which is a branch on `isCompact`, never on a width. No background of its own; the shelf paints the card. `surfaces` gains `shelf-widget`. This is the second thing that starts the clock: `installState.statePublisher` with `activeWidgetIDs` containing `weather` keeps the model running while the widget is on a shelf, seated or not, and the two conditions are or-ed in one place.

Accept:

- [x] `shelf-widget.png` shows the solo composition alone and the paired one beside the harness's second widget, on both shapes.
- [x] `DropletTests`: an install state with the widget active starts the clock with the activity unseated; removing it with the activity still unseated stops it; with the activity seated it keeps running.
- [ ] In the Playground the widget is under its own icon on the Widgets page, opens solo, and pairs when the media player's widget is added beside it; a tap on the compact row's pill lands on it.

Commit: `Put the weather on the shelf, alone and beside another`

#### OW-12 · The room

P1 · M · settings

Done in `579b8fa`. The harness's sidebar search does not read `settingsSearchEntries`, so the first box is checked by `RoomTests` against the entries. The second box is met by `RoomTests` too, because a shot run cannot type: choosing a city writes `city` alone, and every control together writes the four keys and nothing else. The third waits for the Playground; the one-request-per-pause half of it is `RoomTests` and the log line each request writes (docs/notes.md, OW-12).

`SettingsPaneProviding`, a pane built from `DropletSettingsCard` and its rows so it stays in step with Droppy's own pages. A city row: `DropletStackedRow` with a `TextField` in it (the SDK has no text field row of its own; this is the one place the pane goes off the components, and the card says so in `docs/notes.md`), typing runs the geocoder after a pause of 400 ms and lists up to five matches as `DropletControlRow`s with a `DropletValuePill` for the country; choosing one writes `city`. Then a `DropletGroupedPickerRow` for the unit, a `DropletGroupedPickerRow` for the interval (15, 30, 60 minutes) with `SettingsGroupPosition` set so the group draws its corners, and a `DropletToggleRow` "Keep on the notch" with the subtitle "Off, the weather shows while the pointer rests on the notch." Sentence case throughout. `settingsSearchEntries` for city, unit, interval and the pin. `surfaces` gains `settings-pane`.

Accept:

- [x] `settings-pane.png` shows the card with its rows and the harness's search finds "Keep on the notch".
- [x] `preferences.png` after choosing a city in the harness shows `city`, `unit`, `intervalMinutes` and `pinned` and nothing else written.
- [ ] Choosing a city in the Playground's Store row pane puts its temperature on the wing within the interval, and `activity.png` shows one geocoder request per chosen city, none per keystroke.

Commit: `A room with a city in it`

#### OW-13 · Degrees the way the user counts them

P2 · S · model

Done in `079fd83`.

The unit preference, `celsius` by default, `fahrenheit` on request, converted from the one reading in Celsius rather than fetched twice: `WeatherReading.degrees(in:)` rounds after converting, so 25.5 °C is 26° and 78° (77.9 rounded), and feels-like follows. The city's own time zone from OW-3 is what `Ago` is not measured in, because an age is a duration; it is what a future hourly row would be labelled in, and the note says so.

Accept:

- [x] `UnitsTests`: 25.5 °C reads "26°" and "78°"; -0.4 °C reads "0°" in both, never "-0°".
- [x] Flipping the unit in the pane redraws the wing without a fetch, asserted with the counting fetcher.

Commit: `Degrees the way the user counts them`

#### OW-14 · Fixed skies for the harness

P2 · S · setup

Done in `8eaab3a`. The harness has no flag to switch a capability off, so `make offline` hands the built harness a copy of the manifest without `network-client` and `check-report.py --offline` asserts nothing was granted and the wing still publishes; `make shots` itself stays the run with the switch on, which OW-6's capabilities box needs.

`environment.isHarness` and an `OW_DEMO` variable read once at activation: in the harness, or with `OW_DEMO=1`, the fetcher is `DemoWeather`, which answers 25.5°, feels 24.2°, code 2, day, from Istanbul, with no request; `OW_DEMO=stale` answers once and refuses after two seconds, which is what an aeroplane looks like. The shots never touch the network, and neither does a Playground run that carries the variable.

Accept:

- [x] `make shots` runs with the harness's `network-client` switch off and every shot still carries a temperature.
- [x] `DemoTests`: with `OW_DEMO=stale` the second read throws `refused` and the model's `isStale` flips with the reading still up.

Commit: `A sky the harness can count on`

#### OW-15 · The icon and the avatar

P1 · M · look

Done in `f42f738`. The 28 pt render is `shots/icon-28pt.png` (and `@2x`): a sun and a cloud, so the cloud kept its lumps.

`scripts/make-icon.swift` renders the sun behind a cloud, this repo's own shapes, into `OriWeather.icon/Assets/mark.png` at 1024 with the artwork inside the centre 820, no baked corners and no shadow, because Icon Composer adds both; `OriWeather.icon/icon.json` declares one group, one layer at scale 0.8, a flat fill and no gradient of consequence. `Assets/Creator.png` is Meric's mark, square, unrounded, at least 256 px, rendered by the same script from OriNotch's notch-with-wings unless he hands over another; the Store clips it to a circle itself. `make icon` runs the script and is part of `make test`'s validate step by way of `droppykit validate`.

Accept:

- [x] `droppykit validate` passes the icon and the avatar checks, and `overview.png` shows the icon on the identity card.
- [x] The icon read at 28 pt (a 28 by 28 render from the same script, kept beside the shots) is a sun and a cloud and not a blob; if it is a blob, the cloud loses a lump before the rays get sharper.

Commit: `An icon that is a sun behind a cloud`

#### OW-16 · What the droplet costs the Playground

P1 · M · energy

Done in `acbca18`. The unseated run is the droplet with no city and no demo sky, which publishes nil and is never seated; the Playground offers no way to unseat a publishing droplet without music, and nothing in this session could start its player. The log shows no clock started rather than one stopped.

`scripts/energy.sh` after OriNotch's, pointed at the `DroppyPlayground` process: idle CPU averaged over a minute, idle wakeups a second and `top`'s POWER figure, sampled twice, once with the droplet removed from its folder and once installed, seated and pinned, on the same wallpaper with the same player state. The figures and their difference go into `docs/energy/<date>.md`; the first report is the baseline and `make energy` fails on a difference past D6's line (no added idle wakeups within noise, no timer while unseated and unshelved, which the script checks by reading the droplet's own log line for the clock's state). `make energy` joins the gate from this card onward.

Accept:

- [x] The baseline report exists and names both runs' figures.
- [x] With the activity unseated and the widget off the shelf, the log shows the clock stopped and the wakeup figure equals the removed run's within noise.

Commit: `Measure what the guest costs the host`

#### OW-17 · The words on the Store row

P1 · S · ship

Done in `8fd0ce2`.

`droplet.json` filled in: `summary` under 60 characters ("OriNotch's weather, on the wing when nothing else wants it" is 58), a `description` of two paragraphs in Meric's voice, `category`, `keywords`, `screenshots` chosen from the shots and copied into `Assets/`, `creator` with his name, `community`, his URL and the avatar, `kit.minAPI` at the oldest API the code calls (1.1.0 unless a card used something newer, and the card that did says so), `minAppVersion` 15.3.0, `version` 1.0.0. `docs/notes.md` gains the review's five reasons for sending a droplet back and, beside each, the card that answered it.

Accept:

- [x] `droppykit validate` says "Ready to submit." and the manifest's `capabilities` is exactly `["network-client"]`.
- [x] `overview.png` shows the summary, the creator and the icon as the Store row would.

Commit: `Say what it is in sixty characters`

#### OW-20 · The status widgets row

P1 · M · lock screen

Done in `e6f8132`. Added after OW-17 at Meric's request.

`LockScreenStatusProviding` for Droppy's status widgets row: the SF Symbol nearest each mark, the degrees and the condition in the horizontal style, the degrees in the ring and a short caption in the rounded one, the age when stale, nothing without a reading, independent of the pin. The Mac locked with its screen awake counts as seen, so the clock runs then and only then, and only with `lock-screen` granted.

Accept:

- [x] Both styles filled, by day and by night, and stale, in `LockScreenTests`; every code has a symbol and a caption of eight letters at most.
- [x] Locked and awake runs the clock; the display asleep, unlocked or ungranted does not.
- [x] `lock-screen.png` shows both styles, the report has `lock-screen-status` provided, and `make energy` is inside D6.
- [ ] The row seen on the real lock screen, which needs the Mac locked.

Commit: `Put the weather in the status widgets row`

## In progress

## Ready

### Phase 1: a droplet that loads

### Phase 2: the wing

#### OW-10 · Look pass against OriNotch

P1 · S · look · manual

Waiting for eyes: it needs both apps on the real screen, one after the other, and this session was not given the Playground's window. What the pass should find, read from both codebases, is in `docs/look.md`.

`make run` OriNotch with `ORI_DEMO=weather` and take a screenshot of its wing and its card; quit it; `make install` this droplet with `OW_DEMO=1` in the Playground and take the same two. Side by side: the mark, the degrees, the dimming, the words. Differences in size are D3's and are expected (14 against 13, 11 against 12); differences in composition are this card's to fix. What is learnt goes into `docs/look.md`, and the two screenshots are kept under `docs/look/` for the next pass.

Accept:

- [ ] Composition matches within 4 pt on both surfaces after the host's insets are accounted for; the sizes that differ are the ones D3 names and no others.
- [ ] Never both apps at once (D8).

Commit: `The same weather on the other notch`

### Phase 3: the shelf and the room

### Phase 4: ship it

#### OW-18 · The repository and the submission

P0 · M · ship

In progress: the README, the licence and the Store text are committed, the history is scrubbed of the home path (docs/notes.md, "Before the repository went public"), and `make test` and `make energy` are green. What is left is outward: `gh repo create realmeric/OriWeather --public`, pinning `source.commit`, and `droppykit submit`, whose form Meric completes with his name and an address.

`README.md` in Meric's voice: what it is, what it needs (Droppy 15.3 or the Playground), what it sends (a rounded coordinate to Open-Meteo, a city name to its geocoder, nothing else), what it does not do (no location, no account). `LICENSE` is MIT (D7). `gh repo create realmeric/OriWeather --public --source . --push` after Meric says so. `droppykit submit` opens the intake with the repository, the commit and the id filled in and refuses on uncommitted changes, so this card commits before it runs; the `DS-` reference the page answers with is written at the top of this card on the board, and the email it arrives in is where review replies. `source.repository` and `source.commit` in the manifest name that commit, which means the manifest is written, committed, and then the commit hash is the one submitted, in that order.

Accept:

- [ ] The repository is public, the pinned commit is on the remote, and `droppykit submit` accepted it.
- [ ] The reference is on the board.

Commit: `Submit the commit and write down the reference`

#### OW-19 · A week on the real notch

P1 · S · ship · manual

After acceptance. Update Droppy to 15.3, put the signed bundle Droppy delivers under `~/Library/Application Support/Droppy/Droplets/ori-weather/OriWeather.droplet`, relaunch, and read the Store row. Switch Droppy's own weather droplet off so two weathers do not argue, turn "Keep on the notch" on, choose the city. Then a week of use, and every irritation is one line under Backlog, which is the only list of what is worth building next. If review sent it back instead, its reasons become cards at the top of Ready and this card waits.

Accept:

- [ ] The row says loaded in Droppy, not only in the Playground, and the wing carries the temperature at rest with music stopped and gives the seat up when music plays.
- [ ] Seven days later the Backlog has the week in it.

Commit: `Run it on the notch it was for`

## Backlog

Unranked. Promote by writing a card.

## Wishlist

Not queued. Each is a surface the SDK mounts and this droplet does not need to be the thing it is.

- The lock screen chip: `LockScreenStatusProviding` takes an `SF Symbol` name and text, not a view, so the mark cannot go there; the row would be a symbol and "26° Partly cloudy". Small, and it is Droppy's chip, not ours.
- An hourly row in the card: Open-Meteo's `hourly=temperature_2m,weather_code` for the next six hours, six marks and six numbers in the 59 pt the card has, labelled in the city's time zone from OW-3. The card's height is fixed by the host, so it is a second row in the shelf widget rather than in the hover card.
- A HUD when the sky turns: `hud` capability and `host.hud.present` with a strip that says "Rain in an hour" once, from the hourly row above; the one thing that would make the droplet speak first. Needs the capability declared, which the user sees, so it waits for a reason.
- A menu bar extra: the degrees in the menu bar for Macs without a notch. `MenuBarExtraProviding` exists; the wing does not on those Macs, only the island, so the case is real and small.
