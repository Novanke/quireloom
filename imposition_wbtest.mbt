///|
test "hand-worked sixteen-page booklet" {
  let p = impose(16, 16).unwrap()
  assert_eq(p.sheets.length(), 4)
  assert_eq(p.sheets[0].front, { left: Page(16), right: Page(1), rotation: 0, })
  assert_eq(p.sheets[0].back, { left: Page(2), right: Page(15), rotation: 0, })
  assert_eq(p.sheets[3].front, { left: Page(10), right: Page(7), rotation: 0, })
  assert_eq(p.sheets[3].back, { left: Page(8), right: Page(9), rotation: 0, })
}

///|
test "blank slots and multi-gathering offsets" {
  let p = impose(19, 16).unwrap()
  assert_eq(p.sheets[4].front, { left: Blank, right: Page(17), rotation: 0, })
  assert_eq(p.sheets[4].back, { left: Page(18), right: Page(19), rotation: 0, })
}
