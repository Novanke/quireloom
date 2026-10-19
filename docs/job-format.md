# JSON print jobs (schema 1)

AI-assisted technical documentation. The complete runnable request is
[`examples/workbook.json`](../examples/workbook.json). No source PDF is read: a
source is a label with a declared page count, and output refers to that label.

## Fields

Unknown fields and incorrect types are rejected, with a path in `WorkflowError`.
JSON duplicate keys follow the core parser's last-value behavior; avoid duplicate
keys. Input is limited to 2,000,000 UTF-16 code units and nesting depth 32.

| Field | Required / default | Meaning |
| --- | --- | --- |
| `schema` | 1 | Only version 1 is accepted |
| `sections` | required | 1–1000 ordered source sections |
| `sections[].source` | required | Nonblank source label, at most 128 UTF-16 units |
| `sections[].source_pages` | required | Declared source length, 1–100000; same label must have same length |
| `sections[].selection` | required | Comma-separated positive page numbers, inclusive ranges, or `b` |
| `sections[].start_on_recto` | false | Insert a blank if needed so this section starts at an odd logical page |
| `maximum` | 16 | Maximum pages per gathering, 4–128 in multiples of four |
| `policy` | `balanced` | `balanced` minimizes size difference; `fill` fills earlier gatherings |
| `gatherings` | absent | Explicit capacities instead of `maximum`/`policy`, e.g. `[12,8]` |
| `binding` | `left` | `left` or `right` |
| `duplex` | `long-edge` | `long-edge` or `short-edge`, using the geometric convention in semantics.md |
| `paper.width`, `paper.height` | required | 1–10000 mm |
| `paper.margin`, `paper.gutter` | 10, 0 | Integer mm, 0–10000 |
| `paper.creep` | 0 | Inward shift per sheet depth, 0–1000 mm, subject to collision checks |
| `print.copies` | 1 | 1–1000, with at most 100000 physical sheets in a job |
| `print.reverse_sheets` | false | Reverse sheet order before collation |
| `print.collation` | `collated` | `collated` prints each copy; `uncollated` repeats each sheet |
| `print.mode` | `automatic` | `automatic` interleaves fronts/backs; `manual` produces two passes |
| `print.back_stack` | `reversed` in manual mode | `same` or `reversed`; forbidden in automatic mode |

`5-3,b,1,1` preserves exactly that order, including both references to page 1.
Each section's selection is checked against its declared source length. The whole
assembled document, including authored/alignment blanks, is limited to 100000
logical pages. Padding is added only at the final gathering and never exceeds
three slots. Explicit capacities cannot contain empty trailing gatherings.

Balanced planning first finds the minimum number of gatherings permitted by the
maximum. It divides whole sheets evenly among those gatherings, assigning extra
sheets to earlier ones. This makes sizes differ by at most four pages and does
not add sheets compared with fill planning. It does not optimize paper stock,
binding strength or independently folded chapter boundaries.

## Library pipeline

`parse_job(text)` checks the JSON schema; `build_job(spec)` assembles the document,
plans gatherings, imposes logical slots, checks paper geometry and schedules
printing. Structural/geometry/resource errors return `Err`. Repeated source
references and blank-content jobs are advisories in `preflight` and manifest
issues; repeats are allowed on purpose.

`job_spec_json` serializes a validated request for round trips. `job_manifest`
is a resolved report, not a request: each face has logical positions, source/page
references and a padding flag. Internal sheet indices are zero-based; exported
manifest/CSV sheet, copy, gathering and command-line sheet numbers are one-based.
Nesting depth is zero-based everywhere. `job_csv` emits one record per impression;
quoted source fields may contain newlines, so use a real CSV parser.

Source identifiers are metadata; treat exported CSV cells as text when importing
into a spreadsheet. JSON uses the core serializer and SVG labels are XML escaped.

## Command line

```powershell
$job = Get-Content examples/workbook.json -Raw
moon run --target wasm-gc cmd/quireloom -- --job $job --format manifest > manifest.json
moon run --target js cmd/quireloom -- --job $job --format csv > schedule.csv
moon run cmd/quireloom -- --job $job --format normalize > normalized.json
moon run cmd/quireloom -- --job $job --format proof --sheet 1 --back > back.svg
moon run cmd/quireloom -- --job $job --format atlas --first 1 --count 5 > atlas.svg
```

In a POSIX shell use `job="$(cat examples/workbook.json)"` and pass `--job "$job"`.
The executable accepts inline JSON; file reading/redirection belong to the shell.
`run_command(argv)` provides the same pure adapter to embedding applications.
Invalid options or jobs produce `Err`; the executable unwraps that result and
exits with a runtime error. Atlas ranges contain 1–64 sheets; paginate larger jobs.

Manual printing lists fronts first, then backs paired according to the declared
stack permutation. Print an eight-page numbered calibration, fold and check both
reading order and physical refeed. This library cannot choose driver options or
confirm your printer's feed behavior. A proof contains labels and fold guides,
not rearranged PDF artwork or production colour-managed pages.
