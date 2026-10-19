///|
test "schedule verifier rejects swapped backs duplicates and wrong collation" {
  let doc = assemble_document([
    { source: "x", source_pages: 12, selection: "1-12", start_on_recto: false, },
  ]).unwrap()
  let booklet = impose_document(
    doc,
    plan_gatherings(12, 8, Balanced).unwrap(),
    Right,
    ShortEdge,
  ).unwrap()
  for mode in [Automatic, Manual(SameOrder), Manual(Reversed)] {
    for collation in [Collated, Uncollated] {
      for reverse_sheets in [false, true] {
        let schedule = schedule_print(booklet, {
          copies: 3,
          reverse_sheets,
          collation,
          mode,
        }).unwrap()
        assert_eq(verify_schedule(booklet, schedule), Ok(()))
        let pass = schedule.passes[schedule.passes.length() - 1]
        let last = pass.impressions[pass.impressions.length() - 1]
        pass.impressions[pass.impressions.length() - 1] = pass.impressions[0]
        assert_true(verify_schedule(booklet, schedule) is Err(_))
        pass.impressions[pass.impressions.length() - 1] = last
        let a = pass.impressions[0]
        pass.impressions[0] = pass.impressions[1]
        pass.impressions[1] = a
        assert_true(verify_schedule(booklet, schedule) is Err(_))
      }
    }
  }
}
