///|
test "manual refeed pairs reverse stacks across collated copies" {
  let doc = assemble_document([
    {
      source: "zine",
      source_pages: 8,
      selection: "1-8",
      start_on_recto: false,
    },
  ]).unwrap()
  let booklet = impose_document(
    doc,
    plan_gatherings(8, 8, Fill).unwrap(),
    Left,
    LongEdge,
  ).unwrap()
  let options : PrintOptions = {
    copies: 2,
    reverse_sheets: false,
    collation: Collated,
    mode: Manual(Reversed),
  }
  let schedule = schedule_print(booklet, options).unwrap()
  assert_eq(schedule.passes.length(), 2)
  assert_true(schedule.passes[1].reload)
  assert_eq(
    schedule.passes[0].impressions.map(fn(i) { (i.copy, i.sheet, i.back) }),
    [(1, 0, false), (1, 1, false), (2, 0, false), (2, 1, false)],
  )
  assert_eq(
    schedule.passes[1].impressions.map(fn(i) { (i.copy, i.sheet, i.back) }),
    [(2, 1, true), (2, 0, true), (1, 1, true), (1, 0, true)],
  )
  let automatic = schedule_print(booklet, {
    ..options,
    mode: Automatic,
    reverse_sheets: true,
    collation: Uncollated,
  }).unwrap()
  assert_eq(
    automatic.passes[0].impressions.map(fn(i) { (i.copy, i.sheet, i.back) }),
    [
      (1, 1, false),
      (1, 1, true),
      (2, 1, false),
      (2, 1, true),
      (1, 0, false),
      (1, 0, true),
      (2, 0, false),
      (2, 0, true),
    ],
  )
  assert_true(schedule_print(booklet, { ..options, copies: 0, }) is Err(_))
}
