# Ori Weather

The weather from OriNotch, drawn on Droppy's notch.

A mark and the temperature on the wing when nothing else wants the notch.
Hover it and the wing grows into a card: the condition, the city, what it
feels like. Put it on the shelf and it sits there too, alone or beside another
widget. When the network goes, the last reading stays up, dimmed, with how old
it is where the condition was.

It is a Droplet, an extension that runs inside [Droppy](https://getdroppy.app),
built with [DroppyKit](https://gitlab.com/droppyformac1/droppykit) 1.2.1.

## What it needs

Droppy 15.3 or later, with the droplet signed by the Droppy Store. Or
[Droppy Playground](https://getdroppy.app/download/playground), the free app
that loads a droplet straight from `droppykit build`.

## What it sends

A city's name to Open-Meteo's geocoder while you type it into the settings
pane, once the typing has paused. A coordinate rounded to two decimals, about a
kilometre, to Open-Meteo's forecast, once every half hour unless you choose 15
minutes or an hour, and only while the weather is on the notch or the shelf.

Nothing else, to nobody else. Open-Meteo needs no key and no account.

## What it does not do

It does not know where your Mac is. There is no location permission to grant,
because it never asks; you name the city instead.

Why a city and not a location?

Because a droplet runs inside Droppy with Droppy's permissions, and DroppyKit
has no location capability to declare. A droplet that quietly used Droppy's
own location access would be exactly what the Store's review is there to
catch.

It does not run while you cannot see it. Off the notch and off the shelf there
is no timer and no request; the last reading waits until it is shown again, and
is only fetched again if it is older than the interval.

## Building it

```bash
make test      # unit tests, the bundle, the Store's checks, the harness's verdict
make install   # into Droppy Playground
make energy    # what it costs the Playground, against the Playground without it
```

`make test` needs the DroppyKit checkout at `~/Documents/Projects/apps/droppykit`.
`OW_DEMO=1 make install` puts a fixed sky in the Playground without asking the
network anything; `OW_DEMO=stale` shows what an aeroplane looks like.

The limit worth knowing: the harness draws every surface at Droppy's own
metrics, but it does not decide who gets the notch. What the droplet does when
music takes the seat, or when the pointer rests on a closed notch with pinning
off, has been reasoned about and logged, not yet watched on the real Droppy.

## Licence

MIT. See [LICENSE](LICENSE).
