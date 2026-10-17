// Whitebox tests run within the package scope.
// Use them to validate internal helpers or invariants.
// Keep them focused; public behavior belongs in `_test.mbt`.

///|
test "reject invalid and overflow-prone configuration" {
  assert_eq(validate_config(0, 16), Err(PageCount))
  assert_eq(validate_config(100001, 16), Err(PageCount))
  assert_eq(validate_config(20, 6), Err(SignatureSize))
  assert_eq(validate_config(20, 132), Err(SignatureSize))
  assert_eq(validate_config(20, 16), Ok(()))
}
