///|
test "chapter assembly keeps source identity and inserts recto blanks" {
  let doc = assemble_document([
    { source: "cover", source_pages: 2, selection: "1", start_on_recto: false, },
    {
      source: "body",
      source_pages: 4,
      selection: "4-2,b",
      start_on_recto: true,
    },
  ]).unwrap()
  assert_eq(doc.pages, [
    Source("cover", 1),
    Empty,
    Source("body", 4),
    Source("body", 3),
    Source("body", 2),
    Empty,
  ])
  assert_eq(doc.sections[1].first, 3)
  assert_eq(validate_document(doc), Ok(()))
  assert_true(
    assemble_document([
      { source: "x", source_pages: 2, selection: "1", start_on_recto: false, },
      { source: "x", source_pages: 3, selection: "1", start_on_recto: false, },
    ])
    is Err(_),
  )
  assert_true(
    validate_document({ pages: [Source("x", 0)], sections: [], }) is Err(_),
  )
}
