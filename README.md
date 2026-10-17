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

`cmd/main` demonstrates a 15-page zine, a 35-page workbook split into three
gatherings, and a 23-page right-bound art booklet. `cmd/proof` emits a numbered
SVG calibration sheet. These are runnable examples, not an argument-driven CLI.

## Library use

Add `"Novanke/quireloom" @quire` to a local consumer's `moon.pkg` imports.
The package is **not yet published to Mooncakes**; clone it and use a workspace
for local integration until a registry release is confirmed.

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

## Boundaries and validation

Supports once-folded, nested two-up booklets, 1–100,000 pages and gathering sizes
4–128 in multiples of four. No PDF input, font rendering, printer control,
multi-fold signatures or colour-management implementation is claimed.
See [printing semantics](docs/semantics.md) for driver calibration and geometry.

Local verification used moon 0.1.20261012 and moonc v0.10.15+943464bfa on Windows.
13 tests pass on each of wasm-gc and js. One test enumerates 2048 configurations;
these are cases within one test block, not 2048 separate tests. Hand-worked maps,
corruption tests and a 100,000-page boundary case complement the invariant checks.
CI checks formatting, interface drift, check/test/build and runnable examples on
both backends using the current official toolchain.

## Development and provenance

Original implementation of standard booklet imposition concepts; no third-party
implementation was copied or ported. Apache-2.0. AI assisted implementation,
tests and technical documentation. There is no claim of formal verification,
production press certification, competition acceptance or complete historical
novelty verification.

Before the October 31 deadline: obtain the complete historical project list,
confirm the scope with the organizer, run a physical folded proof, polish the
public API and publish a verified Mooncakes release. The entrant writes the
competition proposal personally and completes identity and consent fields.
