///|
test "right binding and short edge rotate physical faces" {
  let right = impose_with(8, 8, Right, LongEdge).unwrap()
  assert_eq(right.sheets[0].front, {
    left: Page(1),
    right: Page(8),
    rotation: 0,
  })
  assert_eq(right.sheets[0].back, {
    left: Page(7),
    right: Page(2),
    rotation: 0,
  })
  let short = impose_with(8, 8, Left, ShortEdge).unwrap()
  assert_eq(short.sheets[0].back, {
    left: Page(7),
    right: Page(2),
    rotation: 180,
  })
  let both = impose_with(8, 8, Right, ShortEdge).unwrap()
  assert_eq(both.sheets[0].back, {
    left: Page(2),
    right: Page(7),
    rotation: 180,
  })
}
