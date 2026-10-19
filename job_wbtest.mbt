///|
fn fixture_job() -> String {
  "{\"sections\":[{\"source\":\"workbook\",\"source_pages\":19,\"selection\":\"1-19\"}],\"maximum\":16,\"paper\":{\"width\":297,\"height\":210,\"gutter\":8,\"creep\":1},\"print\":{\"copies\":2,\"mode\":\"manual\"}}"
}

///|
test "strict job schema builds complete calibrated jobs and rejects typos and fractions" {
  let job = build_job(parse_job(fixture_job()).unwrap()).unwrap()
  assert_eq(job.booklet.gatherings.map(fn(g) { g.pages }), [12, 8])
  assert_eq(job.schedule.passes.length(), 2)
  assert_eq(verify_schedule(job.booklet, job.schedule), Ok(()))
  for
    text in [
      "{}", "[]", "{\"schema\":2}", "{\"typo\":1}", "{\"sections\":[],\"paper\":{}}",
    ] {
    assert_true(parse_job(text) is Err(_))
  }
  assert_true(
    parse_job(fixture_job().replace(old="\"copies\":2", new="\"copies\":1.5"))
    is Err(_),
  )
  assert_true(
    parse_job(
      fixture_job().replace(old="\"mode\":\"manual\"", new="\"mode\":\"wrong\""),
    )
    is Err(_),
  )
  let spec = parse_job(
    fixture_job().replace(old="\"gutter\":8", new="\"gutter\":0"),
  ).unwrap()
  assert_true(build_job(spec) is Err(_))
}
