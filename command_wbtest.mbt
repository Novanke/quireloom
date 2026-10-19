///|
test "command validates options and generates all supported integration formats" {
  assert_true(run_command(["--help"]).unwrap().contains("QuireLoom"))
  for format in ["manifest", "csv", "normalize", "proof", "atlas"] {
    assert_true(
      !run_command(["--job", fixture_job(), "--format", format])
      .unwrap()
      .is_empty(),
    )
  }
  for
    args in [
      ["--job"],
      ["--unknown"],
      ["--format", "csv"],
      ["--job", fixture_job(), "--job", fixture_job()],
      ["--job", fixture_job(), "--sheet", "1"],
      ["--job", fixture_job(), "--format", "proof", "--sheet", "0"],
      ["--job", fixture_job(), "--format", "atlas", "--count", "65"],
    ] {
    assert_true(run_command(args) is Err(_))
  }
}
