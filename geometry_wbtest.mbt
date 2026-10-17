///|
test "integer paper layout and bounded creep" {
  let p : Paper = { width: 420, height: 297, margin: 10, gutter: 20, creep: 2, }
  let g = layout(p, 3).unwrap()
  assert_eq(g.left, { x: 16, y: 10, width: 190, height: 277, })
  assert_eq(g.right.x, 214)
  assert_eq(layout(p, 6), Err(Geometry))
  assert_eq(
    layout({ width: 20, height: 20, margin: 10, gutter: 0, creep: 0, }, 0),
    Err(Geometry),
  )
  assert_eq(layout(p, 32), Err(Geometry))
}
