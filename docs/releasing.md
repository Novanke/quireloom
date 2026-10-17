# Release procedure

The owner requires Mooncakes publication for every completed project update that
will be used for final competition review. Pushing GitHub commits is only one
part of delivery. Do not describe a version as published until both upload and
installation from the registry have been verified.

1. Inspect the working tree and decide the release scope. The first release is
   `0.1.0`; later releases must use a new semantic version in `moon.mod`.
2. Run `moon info`, `moon fmt --check`, and check/test/build for both `wasm-gc` and
   `js`. Run `cmd/main` and generate the `cmd/proof` SVG example. Review public
   interface changes and verify the relevant GitHub CI run.
3. Update installation instructions, source provenance and release notes as
   needed. Avoid claiming unverified capabilities or publication status.
4. Run `moon package --list` and inspect the archive's file list. The release
   directory is the repository root, not the enclosing chat workspace. Personal
   registration materials live outside this repository and must not be included.
5. Commit and push the release, then authenticate using the official Mooncakes
   flow and run `moon publish` from the module root. Use the owner's publisher
   account for the `Novanke` namespace. Do not publish under another account to
   work around authentication failures.
6. Create a clean consumer in a temporary workspace outside the repository. Run
   `moon add Novanke/quireloom@<version>`, import `"Novanke/quireloom" @quire` in
   its `moon.pkg`, and run the following on `wasm-gc` and `js`:

   ```moonbit
   fn main {
     let plan = @quire.impose_with(19, 16, Left, ShortEdge).unwrap()
     @quire.verify(plan).unwrap()
     println(@quire.csv_report(plan).unwrap())
   }
   ```

7. Confirm the exact version and documentation on the public registry, and
   report the registry URL, release commit, tested backends and any limitations.
   A registry indexing delay or failed consumer install is still incomplete
   verification, even if `moon publish` reports a successful upload.

Use normal interactive authentication or an existing publisher credential. Do
not add persistent CI tokens or change account permissions without the owner's
approval. Never echo tokens or put them in tracked scripts.
