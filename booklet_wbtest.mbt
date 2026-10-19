///|
test "mixed signatures recover distinct source references under all orientations" {
  let document = assemble_document([
    {
      source: "body",
      source_pages: 19,
      selection: "19-1",
      start_on_recto: false,
    },
  ]).unwrap()
  for binding in [Left, Right] {
    for duplex in [LongEdge, ShortEdge] {
      let booklet = impose_document(
        document,
        explicit_gatherings(19, [12, 8]).unwrap(),
        binding,
        duplex,
      ).unwrap()
      let recovered = recover_booklet(booklet).unwrap()
      assert_eq(recovered[0], Source("body", 19))
      assert_eq(recovered[18], Source("body", 1))
      assert_eq(recovered[19], Empty)
      let first = booklet.sheets[0]
      booklet.sheets[0] = {
        ..first,
        front: { ..first.front, right: Page(2), },
      }
      assert_true(recover_booklet(booklet) is Err(_))
    }
  }
}
