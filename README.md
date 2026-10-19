# QuireLoom

Pure MoonBit booklet imposition: turn a logical page count into explicit sheet
faces, then verify that folding recovers the original reading order.

Initial development for the October 2026 MoonBit hackathon. AI-assisted code and
technical documentation; the entrant must understand the implementation and
write the competition proposal personally, as required by the form.

This repository starts a new printing and publishing tool. It is independent of
`Novanke/moonmorph`, which handles reversible JSON migrations.

## Run

Install the [official MoonBit toolchain](https://www.moonbitlang.com/download/).
No third-party Mooncakes dependency is needed.

```sh
git clone https://github.com/Novanke/quireloom.git
cd quireloom
moon check --target wasm-gc --deny-warn
moon test --target wasm-gc --deny-warn
moon build --target wasm-gc --deny-warn
moon run cmd/main
moon run cmd/proof > proof.svg
```

`cmd/main` demonstrates three basic scenarios. `cmd/proof` emits a numbered
calibration sheet. The new `cmd/quireloom` compiles complete JSON print jobs:

```powershell
$job = Get-Content examples/workbook.json -Raw
moon run cmd/quireloom -- --job $job --format manifest
moon run cmd/quireloom -- --job $job --format csv
moon run cmd/quireloom -- --job $job --format atlas --first 1 --count 5 > atlas.svg
```

See [the JSON job format and command reference](docs/job-format.md). The example
combines cover/body sources with a recto alignment blank, balances two gatherings,
and schedules two copies in separate manual-duplex passes. Source artwork is not
embedded. Calibrate the physical printer refeed order before printing.

## Library use

Install the 0.2.0 release from Mooncakes in your consumer module:

```sh
moon add Novanke/quireloom@0.2.0
```

Add `"Novanke/quireloom" @quire` to the consumer package's `moon.pkg` imports.
See the [registry documentation](https://mooncakes.io/docs/Novanke/quireloom@0.2.0).

```moonbit
let plan = @quire.impose_with(19, 16, Left, ShortEdge).unwrap()
@quire.verify(plan).unwrap()
println(@quire.csv_report(plan).unwrap())
```

- `signatures`: sequential gathering partition and final blank count.
- `impose` / `impose_with`: canonical and oriented front/back page maps.
- `recover` / `verify`: reconstruct folded leaves and reject corrupt plans.
- `layout`: bounded integer paper geometry and explicit inward creep offsets.
- `json_report` / `csv_report`: validated, deterministic integration output.
- `svg_proof`: one sheet face with numbered panels and a fold line.
- `parse_selection` / `assemble_document`: selected ranges, repeated pages,
  authored blanks, source provenance and recto chapter alignment.
- `plan_gatherings` / `explicit_gatherings`: balanced or specified capacities.
- `impose_document` / `recover_booklet`: mixed-gathering imposition and recovery.
- `schedule_print` / `verify_schedule`: copies, collation, reverse order,
  automatic duplex and calibrated manual refeed, with coverage/pairing checks.
- `preflight` / `locate_source`: geometry advisories, blank/repeat accounting
  and lookup of all printed uses of a source page.
- `parse_job` / `build_job`: strict, bounded JSON configuration and job validation.
- `job_spec_json` / `job_manifest` / `job_csv`: reproducible requests, resolved
  source-labelled manifests and actual print-pass records.
- `job_proof` / `proof_atlas` / `run_command`: escaped SVG and CLI integration.

## Boundaries and validation

Supports once-folded, nested two-up booklets, 1–100,000 pages and gathering sizes
4–128 in multiples of four. No PDF input, font rendering, printer control,
multi-fold signatures or colour-management implementation is claimed.
See [printing semantics](docs/semantics.md) for driver calibration and geometry.

Local verification used moon 0.1.20261016 and moonc v0.10.16+b1a0e846e on Windows.
28 tests pass on each of wasm-gc and js. Separate test blocks enumerate 2048
legacy configurations and 8192 generalized configurations; those are cases inside
test blocks. Hand-worked print passes, provenance corruption, JSON/CSV/XML
escaping, 100,000 logical pages and 100,000 physical sheets complement those checks.
CI checks formatting, interface drift, check/test/build and runnable examples on
both backends using the current official toolchain.

The 0.2.0 review supplement includes a [reproducible source audit and 12 substantive
change references](docs/review-evidence.md). Tests, examples and documentation are
excluded from its library-source totals. The organizer determines eligibility.

## Development and provenance

Original implementation of standard booklet imposition concepts; no third-party
implementation was copied or ported. Apache-2.0. AI assisted implementation,
tests and technical documentation. There is no claim of formal verification,
production press certification, competition acceptance or complete historical
novelty verification.

Before the October 31 deadline: obtain the complete historical project list,
confirm the scope with the organizer, run a physical folded proof and polish the
public API. Every completed update intended for final review must also be
published to Mooncakes; see [the release procedure](docs/releasing.md).
The entrant writes the
competition proposal personally and completes identity and consent fields.
