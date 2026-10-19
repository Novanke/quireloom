///|
test "source-labelled proof escapes XML and paginates front back pairs" {
  let spec = parse_job(fixture_job()).unwrap()
  let job = build_job({
    ..spec,
    sections: [
      {
        source: "<script>&\"书",
        source_pages: 19,
        selection: "1-19",
        start_on_recto: false,
      },
    ],
  }).unwrap()
  let svg = proof_atlas(job, 0, 2).unwrap()
  assert_true(svg.contains("&lt;script&gt;&amp;&quot;书"))
  assert_true(!svg.contains("<script>"))
  assert_true(svg.contains("Sheet 2 / gathering 1 / depth 1 / BACK"))
  assert_true(job_proof(job, 3, false).unwrap().contains("PADDING"))
  assert_true(proof_atlas(job, 4, 2) is Err(_))
  assert_true(proof_atlas(job, 0, 65) is Err(_))
}
