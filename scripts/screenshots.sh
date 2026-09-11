#!/bin/zsh
#
# The Store's two screenshots, cut from the harness's tall shots: the wing and
# its card on both shapes, and the widget alone on the shelf. Run after a
# visual change, then read them: they are what the Store row shows.
set -eu
root=${0:a:h:h}
cd "$root"
droppykit=${DROPPYKIT:-${root:h}/droppykit/Scripts/droppykit}
"$droppykit" run -- --shots ./shots/tall --shot-height 1900 >/dev/null
# sips crops as height width, offset as y x, in the shots' 2x pixels.
sips -c 1395 1820 --cropOffset 560 460 shots/tall/live-activity.png --out Assets/wing.png >/dev/null
sips -c 1035 1820 --cropOffset 560 460 shots/tall/shelf-widget.png --out Assets/shelf.png >/dev/null
print "wrote Assets/wing.png and Assets/shelf.png"
