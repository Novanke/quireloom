///|
test "sequential gatherings and minimal final padding" {
  let s = signatures(35, 16).unwrap()
  assert_eq(s.length(), 3)
  assert_eq(s[0], { index: 0, start: 1, pages: 16, real_pages: 16, })
  assert_eq(s[1], { index: 1, start: 17, pages: 16, real_pages: 16, })
  assert_eq(s[2], { index: 2, start: 33, pages: 4, real_pages: 3, })
  assert_eq(signatures(1, 4).unwrap()[0].pages, 4)
  assert_eq(signatures(-1, 16), Err(PageCount))
}
