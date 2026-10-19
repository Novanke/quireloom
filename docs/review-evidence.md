# 0.2.0 technical supplement for re-review

**AI-assisted / AI-generated technical evidence, 2026-10-19.** This is a factual
repository supplement, not the entrant's personally authored competition proposal.
The organizer determines what qualifies as effective source or a valid commit.

The 0.1.0 baseline at `831fbba` was too small: its root library had 349 nonblank,
noncomment source lines under the metric below. Documentation/test commits are
not offered as evidence of ten functional commits. History has not been rewritten
or backdated. The following are new, independently tested functionality and fixes.

## Reproducible source accounting

Run from the repository on PowerShell 7 (`pwsh` on Linux):

```powershell
./scripts/source-audit.ps1
./scripts/source-audit.ps1 -Revision 831fbba
```

| Scope | 0.1.0 baseline | 0.2.0 source |
| --- | ---: | ---: |
| Root library `.mbt` files | 8 | 19 |
| Nonblank, noncomment source lines | 349 | 1991 |
| Function-body lines excluding pure punctuation | 177 | 1154 |

Both columns exclude all `_test.mbt` and `_wbtest.mbt`, `cmd` examples/commands,
generated `.mbti`, `_build`, `.mooncakes`, documentation, configuration and scripts.
The stricter function-body metric also excludes type/enum/import/extension
declarations, attributes, function signatures and brace/bracket-only lines. It
uses this repository's `///|` block convention. It counts code expressions on
normal formatted lines, not characters or generated output. It is a disclosed
local audit method, not a claim to implement an unpublished official formula.

## Functional commit evidence

Each commit includes production `.mbt` behavior and corresponding validation.
The later release/documentation commit is deliberately absent from this list.

| Commit | Production change and behavior | Validation |
| --- | --- | --- |
| [daa84a4](https://github.com/Novanke/quireloom/commit/daa84a4) | `selection.mbt`: bounded page grammar, descending ranges, repeats, authored blanks | syntax, source bounds, 100000-slot expansion limit |
| [3192d52](https://github.com/Novanke/quireloom/commit/3192d52) | `document.mbt`: multi-source chapter assembly and recto alignment | source identity, alignment blank, conflicting source lengths |
| [e93afcc](https://github.com/Novanke/quireloom/commit/e93afcc) | `gatherings.mbt`: balanced and binder-specified mixed capacities | hand-worked 20+16 and 12+8 maps, 256 page counts |
| [573953d](https://github.com/Novanke/quireloom/commit/573953d) | `booklet.mbt`, orientation refactor: generalized imposition and independent fold traversal | all orientation combinations and corrupt logical positions |
| [060fa50](https://github.com/Novanke/quireloom/commit/060fa50) | `schedule.mbt`: copies, collation, reversal, automatic/manual duplex passes | explicit physical pass sequences and invalid copy count |
| [56d1721](https://github.com/Novanke/quireloom/commit/56d1721) | `schedule_verify.mbt`: coverage, pairings, refeed and collation verification | duplicate and swapped impressions across modes |
| [5c87359](https://github.com/Novanke/quireloom/commit/5c87359) | `preflight.mbt`: geometry issues, blank accounting, repeats, source placement lookup | authored vs padding blanks, collision at depth, repeated source lookup |
| [8da7fa7](https://github.com/Novanke/quireloom/commit/8da7fa7) | `job.mbt`: strict schema, typed bounds, complete validated job compilation | unknown fields, fractional copies, invalid enums and clipping |
| [6ad85a8](https://github.com/Novanke/quireloom/commit/6ad85a8) | `job_report.mbt`: reproducible request roundtrip, resolved manifest and print CSV | Unicode, quotes, commas and embedded newline preservation |
| [b91200e](https://github.com/Novanke/quireloom/commit/b91200e) | `job_proof.mbt`: source-labelled physical proofs and paginated atlas | XML injection escaping, padding identity, range limits |
| [3e4f93d](https://github.com/Novanke/quireloom/commit/3e4f93d) | `command.mbt`, `cmd/quireloom`: usable CLI and reusable command adapter | five formats, duplicate/unknown/inapplicable options; real backend runs |
| [d85b635](https://github.com/Novanke/quireloom/commit/d85b635) | provenance/bounds fix in `document.mbt`, `gatherings.mbt` | forged source labels, omitted content, oversized span indices |

Inspect actual patches with `git show <commit> -- '*.mbt'`; do not infer validity
from a commit title or raw commit count alone.

## Validation and reproduction

28 test blocks pass on wasm-gc and js. Two separate blocks enumerate 2048 legacy
configurations and 8192 generalized configurations; these are cases within blocks,
not 10240 separately authored tests. Resource tests cover 100000 logical pages and
100000 physical sheets with four copies. Corrupt passes, bad rotations, provenance
errors, invalid JSON/configuration and output escaping are also checked.

```sh
moon info
moon fmt --check
moon check --target wasm-gc --deny-warn
moon test --target wasm-gc --deny-warn
moon build --target wasm-gc --deny-warn
moon check --target js --deny-warn
moon test --target js --deny-warn
moon build --target js --deny-warn
```

CI also executes `examples/workbook.json` through both CLI backends and compares
manifest, CSV and SVG output byte-for-byte. See README/job-format.md for commands
to reproduce the real cover/body example. Release: `Novanke/quireloom@0.2.0` on
[Mooncakes](https://mooncakes.io/docs/Novanke/quireloom@0.2.0).

This remains a booklet planning/verification library. It does not import/render
PDFs or operate printer drivers, and no physical printer proof has yet been
claimed. AI assistance and incomplete historical-project novelty checks remain
disclosed. The supplement requests re-review of the upgraded repository; it
does not assert that the organizer has accepted it.
