# The Ori rise

*Ori-* is the root of rising: *oriri*, to rise, which gives the orient, where
the sun comes up. Every Ori droplet's icon carries that rise, so a row of them
in Droppy's Store reads as one family before anybody reads a name. The rise is
the signature; what sits above it is the droplet's own.

## What the rise is

A paper ground, the icon document's own fill: a gradient from `#F7F9FC` at the
top to `#C9D3E2` at the bottom.

The top of a sun far larger than the tile, coming up over its bottom edge: a
circle of radius 1.22 × the side, centred 2.02 × the side down, so its crown
sits at 80% of the height. It is filled from `#FFD58F` at the crown to
`#FFA23A` at the edge, with a glow of `#FFB85A` at 55% fading out over 22% of
the side above it. The tile's corners cut it; it runs to the edge on purpose.
It never moves, never changes colour and is always the back layer, `rise.png`.

Above it, the droplet's mark, inside the centre 820 of 1024: shapes in ink
(`#3A4660` to `#262F42`, top to bottom, resting on a soft shadow of their own),
with warm accents in the family's orange and yellow. One mark, not a scene: at
28 pt, the Store's smallest, a second idea is a smudge.

OriWeather's mark is a sun behind an ink cloud; its sun is the droplet's, not
the family's, which is why it sits up and to the right and the rise stays
where it is.

## How it is built

Three layers in the Icon Composer document, back to front, each at scale 1.0
so Icon Composer can light them separately: the rise, then the droplet's
layers. `scripts/make-icon.swift` draws them; `drawRise` is the family's and
the next droplet copies it unchanged, the rest is the droplet's own. The
document adds the rounded corners and the icon's shadow; the layers draw
neither.

## What was tried and dropped

A notch hanging from the top of an ink tile, which read as a clip on
a clipboard. A dawn gradient across the whole tile, which all but disappeared
at 28 pt. A sun always in the top right, which means nothing on a droplet that
is not about the weather. A half sun on a flat sand horizon, which put two
suns on the weather icon. The rising arc was Meric's choice of four.
