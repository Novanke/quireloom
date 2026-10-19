///|
test "requests roundtrip and reports escape arbitrary source identifiers" {
  let spec = parse_job(fixture_job()).unwrap()
  let changed = {
    ..spec,
    sections: [
      {
        source: "a,\"<书>\n",
        source_pages: 19,
        selection: "1-19",
        start_on_recto: true,
      },
    ],
  }
  let serialized = job_spec_json(changed).unwrap()
  let roundtrip = parse_job(serialized).unwrap()
  assert_eq(roundtrip.sections[0].source, "a,\"<书>\n")
  let job = build_job(roundtrip).unwrap()
  assert_true(@json.valid(job_manifest(job).unwrap()))
  assert_true(job_csv(job).unwrap().contains("\"a,\"\"<书>\n\""))
  assert_true(job_manifest(job).unwrap().contains("\"padding_blanks\": 1"))
}
