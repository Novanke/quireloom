// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "Novanke/quireloom"

version = "0.1.0"

readme = "README.md"

repository = "https://github.com/Novanke/quireloom"

license = "Apache-2.0"

keywords = [ "booklet", "imposition", "printing" ]

preferred_target = "wasm-gc"

description = "Deterministic booklet imposition and fold-order verification in pure MoonBit"
