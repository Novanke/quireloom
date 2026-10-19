///|
test "balanced gatherings avoid a thin final gathering without extra sheets" {
  let balanced = plan_gatherings(36, 32, Balanced).unwrap()
  assert_eq(balanced.map(fn(g) { g.pages }), [20, 16])
  assert_eq(explicit_gatherings(19, [12, 8]).unwrap()[1].real_pages, 7)
  for sizes in [[16, 16], [20, 4], [12], [12, 8, 4], [3, 16]] {
    assert_true(explicit_gatherings(19, sizes) is Err(_))
  }
  for pages in 1..<=256 {
    let groups = plan_gatherings(pages, 32, Balanced).unwrap()
    assert_eq(validate_gatherings(pages, groups), Ok(()))
    let mut total = 0
    for group in groups {
      total += group.pages
    }
    assert_eq(total, (pages + 3) / 4 * 4)
    assert_true(groups[0].pages - groups[groups.length() - 1].pages <= 4)
  }
}
