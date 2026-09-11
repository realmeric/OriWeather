# Look

What the weather looks like, in OriNotch and here. Composition, marks and
words are OriNotch's; sizes and the colours of text are Droppy's (D3).

## The two surfaces in OriNotch

The wing. When nothing else wants the notch, OriNotch puts the weather on the
right wing: the mark at 14 pt, five points of space, and the degrees in its
`figure` font (11 pt, medium, monospaced digits) in full white, the pair pushed
to the trailing edge and inset from it by the wing's own inset. No condition
and no city: the wing is a glance, and a glance is a mark and a number.

The card. On the shelf the weather is a capsule: the mark at its card size,
eight points, then a column of the degrees in the `label` font (13 pt, medium,
white) over the condition in the `caption` font (11 pt, regular) in the
tertiary white. The capsule has a faint white fill. When the last read failed
the condition is replaced by how old the reading is ("2 h ago") and the whole
capsule drops to 55% opacity: dimmed rather than hidden, because a temperature
from an hour ago with its age on it is worth more than an empty card.

The marks are OriNotch's own glyphs, filled, never SF Symbols: the sun in a
warm yellow by day and in the secondary white by night, the cloud in the
secondary white, rain in blue, snow in full white, fog in the tertiary white,
and the storm's bolt in the same warm yellow as the sun.

## The same, drawn by a guest

Droppy draws two wings, so the mark goes on the leading one and the degrees on
the trailing one; OriNotch kept both on the right only because its left wing
was busy with artwork. The mark is `DroppyLiveActivityMetrics.iconSize` (13)
and the degrees `labelFontSize` (12), in `notchSurfacePrimaryText`, with no
padding of this droplet's own because the host insets each wing already.

The white ladder is Droppy's: primary white, `notchSurfaceSecondaryText`
(82%) where OriNotch had 65%, `notchSurfaceTertiaryText` (60%) where OriNotch
had 35%. The two tints, the warm yellow and the blue, are the only colours of
this droplet's own, and they live in `Look.swift` with the stale opacity and
the card's mark size.

## The marks, one change

OriNotch's sun draws its rays out to 48% of the side from the centre and then
strokes them with round caps, so a cap pokes past the rect by half the ray's
width: 0.65 pt at 16 pt. In OriNotch that lands in padding nobody sees. On
Droppy's wing, where the host sizes the accessory and clips it, it is the kind
of thing that shaves a ray off without a word, so here the rays stop half a
width short of the edge. `MarksTests` checks every mark stays inside its rect
at 16 and at 13 pt. The other five were already inside.

## OW-10, what the side-by-side should show

Not yet done: it needs OriNotch and the Playground on the real screen one after
the other, and eyes. Read from the two codebases, these are the differences
the pass should find, and every one of them is D3's.

On the wing, OriNotch draws the mark at 14 pt and the degrees at 11 pt, both on
the right wing, five points apart. Here the mark is 13 pt on the left wing and
the degrees 12 pt on the right, each at the outer edge of its wing past the
host's 22 pt inset, with the camera housing between them. Neither dims when
the reading is stale, in either app.

On the card, the two are different surfaces. OriNotch's weather card is a
capsule on its shelf with a faint fill: mark, degrees at 13, condition at 11.
Here the hover card is the host's 59 pt card with no fill of its own: mark at
20, degrees at 20, the condition under them, and the city and "Feels like"
on the right, which OriNotch's capsule does not carry. The shelf widget is the
closer relative of OriNotch's capsule, with the same order left to right and
the same dimming, at shelf sizes.
