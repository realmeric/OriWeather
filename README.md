# OriWeather

Weather on Droppy's notch, drawn with better taste.

A mark and the temperature on the wing when nothing else wants the notch.
Hover it and the wing grows into a card: the condition, the city, what it
feels like. Put it on the shelf and it sits there too, alone or beside another
widget. When the network goes, the last reading stays up, dimmed, with how old
it is where the condition was.

While the Mac is locked it sits in Droppy's status widgets row too, as a
symbol, the degrees and the condition, or the degrees in a ring, whichever
style you picked in Droppy.

"Keep on the notch" decides whether it takes the wings at all; off, it stays
on the shelf. Control-Option-Command-W flips it from anywhere, and Droppy's Settings,
Shortcuts, rebinds it. A press without all three never flips it.

It is a Droplet, an extension that runs inside [Droppy](https://getdroppy.app),
built with [DroppyKit](https://gitlab.com/droppyformac1/droppykit) 1.2.1.

## What it needs

Droppy 15.3 or later, with the droplet signed by the Droppy Store. Or
[Droppy Playground](https://getdroppy.app/download/playground), the free app
that loads a droplet straight from `droppykit build`.

## What it sends

A city's name to Open-Meteo's geocoder, the one you type into the settings
pane once the typing has paused. When the city is found automatically, one
request to GeoJS, which answers with the city your internet address is in; it
sees the address, which Open-Meteo sees anyway, and nothing else. That is asked
at start, on a new network, after sleep and when the time zone changes, never
twice in ten minutes, and only while the weather is on screen. A coordinate rounded to two decimals, about a
kilometre, to Open-Meteo's forecast, once every half hour unless you choose 15
minutes or an hour, and only while the weather is on the notch or the shelf.

Nothing else, to nobody else. Open-Meteo needs no key and no account.

## What it does not do

It does not ask where your Mac is. There is no location permission to grant.
Until you name a city, it uses the city your internet address is in, and
checks that against your time zone: an address in another zone is a VPN, and
then the city the zone is named after is used instead (Europe/Istanbul is
Istanbul).

Why not the Mac's location?

Because a droplet runs inside Droppy with Droppy's permissions, and DroppyKit
has no location capability to declare. A droplet that quietly used Droppy's
own location access would be exactly what the Store's review is there to
catch.

And why not only the time zone?

Because Ankara and Istanbul share one. The address tells cities apart; the
zone only catches it when it lies. The address can still be wrong inside a
country, a VPN exit in the same zone or a mobile network's gateway in the next
city, which is what the city field is for.

It does not run while you cannot see it. Off the notch, off the shelf and off
a lit lock screen there is no timer and no request; the last reading waits until it is shown again, and
is only fetched again if it is older than the interval.

## Building it

```bash
make test      # unit tests, the bundle, the Store's checks, the harness's verdict
make install   # into Droppy Playground
make energy    # what it costs the Playground, against the Playground without it
```

`make test` needs the [DroppyKit](https://gitlab.com/droppyformac1/droppykit)
checkout: `droppykit` on the PATH, or the repository cloned beside this one,
or `make SDK=/path/to/droppykit test`.
`OW_DEMO=1 make install` puts a fixed sky in the Playground without asking the
network anything; `OW_DEMO=stale` shows what an aeroplane looks like.

The limit worth knowing: the harness draws every surface at Droppy's own
metrics, but it does not decide who gets the notch. What the droplet does when
music takes the seat, or when the pointer rests on a closed notch with pinning
off, has been reasoned about and logged, not yet watched on the real Droppy.

## Licence

MIT. See [LICENSE](LICENSE).
