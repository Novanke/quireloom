///|
test "preflight distinguishes authored blanks padding repetition and geometry" {
  let doc = assemble_document([
    {
      source: "body",
      source_pages: 4,
      selection: "1,2,1,b,4",
      start_on_recto: false,
    },
  ]).unwrap()
  let booklet = impose_document(
    doc,
    plan_gatherings(5, 8, Fill).unwrap(),
    Left,
    LongEdge,
  ).unwrap()
  let paper : Paper = {
    width: 297,
    height: 210,
    margin: 10,
    gutter: 4,
    creep: 3,
  }
  let result = preflight(booklet, paper).unwrap()
  assert_eq(
    (
      result.content_pages,
      result.explicit_blanks,
      result.padding_blanks,
      result.repeated_references,
    ),
    (4, 1, 3, 1),
  )
  assert_eq(result.issues.filter(fn(i) { i.blocking }).length(), 1)
  let positions = locate_source(booklet, "body", 1).unwrap()
  assert_eq(positions.map(fn(p) { p.logical_page }), [1, 3])
  assert_eq(locate_source(booklet, "absent", 1).unwrap().length(), 0)
}
