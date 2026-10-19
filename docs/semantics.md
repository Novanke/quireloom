# Printing model

This first section describes the sequential `Plan` API retained from 0.1.0.
The 0.2.0 `Booklet`/`PrintJob` API generalizes source mapping and gathering sizes;
see the additional section below and [the job format](job-format.md).

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

## Assembled documents and print jobs

A `Document` assigns logical positions to source identifiers/page numbers or
authored blanks. Source references may repeat; logical positions never do.
Section spans, when present, must account for source content without overlaps or
false provenance. Recto alignment inserts an authored blank before a section.

Gathering plans may fill to a maximum, balance whole sheets or follow explicit
mixed capacities. Only the final gathering may have up to three padding slots.
`recover_booklet` reconstructs and checks every logical position from supplied
faces before resolving it through the source map. Authored blanks and padding
therefore remain distinguishable in reports even though both contain no artwork.

Print schedules refer to physical `(copy, sheet)` pairs. Automatic schedules
interleave front and back for each pair. Manual schedules put all fronts in pass
one and matching backs in pass two; `back_stack` specifies the calibrated stack
permutation across the entire first pass, including copy boundaries.
`verify_schedule` independently checks coverage, uniqueness, side pairing,
reload markers, collation and that permutation. It cannot observe the printer.
