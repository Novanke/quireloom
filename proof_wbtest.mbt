///|
test "proof shows blank labels and rotated short-edge backs" {
  let p = impose_with(3, 4, Left, ShortEdge).unwrap()
  let paper : Paper = {
    width: 420,
    height: 297,
    margin: 10,
    gutter: 20,
    creep: 0,
  }
  let front = svg_proof(p, paper, 0, false).unwrap()
  assert_true(front.contains("BLANK"))
  assert_true(front.contains("width=\"420mm\""))
  let back = svg_proof(p, paper, 0, true).unwrap()
  assert_true(back.contains("rotate(180"))
  assert_true(svg_proof(p, paper, -1, false) is Err(_))
}
