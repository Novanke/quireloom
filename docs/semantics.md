# Printing model

An input is a sequential book of 1–100,000 logical pages. A gathering (signature)
contains at most 4–128 pages, in multiples of four. Only the final gathering is
padded, to the next multiple of four. Each sheet folds once down the centre;
sheets nest outside to inside. Separate gatherings are bound in order.

For a canonical left-bound gathering, the outer front is `[last, first]` and
the outer back is `[first + 1, last - 1]`. Front and back are each viewed directly
from the printed side. Right binding mirrors the cells. `ShortEdge` swaps back
cells and rotates both labels 180 degrees relative to `LongEdge`.

These names express relative geometric transforms. Printer drivers disagree
about feed direction, landscape auto-rotation and duplex labels. Before a real
run, print an eight-page numbered test at 100% scale, fold it, and confirm the
reading order. Do not infer driver settings from the enum name alone.

`recover` undoes orientation and reads the folded leaves. `verify` checks exact
logical order, blank placement, sheet count, gathering identity, depth and face
rotation. It detects wrong order even when each page is present once. It is
executable validation, not a formal proof or a physical press calibration.

Geometry uses integer millimetres and divides available width into two equal
panels (an odd remaining millimetre stays in the centre gap). Creep is an explicit
inward shift per nesting depth. Overlapping or clipped layouts are rejected.

SVG output contains page-number placeholders and a fold line. The library does
not parse PDFs, render fonts, rearrange source artwork, control printers, handle
multi-fold signatures or promise press-ready colour management.
