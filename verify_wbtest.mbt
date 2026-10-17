///|
test "physical leaf traversal restores multi-gathering reading order" {
  let p = impose_with(19, 16, Right, ShortEdge).unwrap()
  assert_eq(verify(p), Ok(()))
  let recovered = recover(p).unwrap()
  assert_eq(recovered.length(), 20)
  assert_eq(recovered[0], Page(1))
  assert_eq(recovered[18], Page(19))
  assert_eq(recovered[19], Blank)
}

///|
test "detect wrong page order even when all pages occur once" {
  let p = impose(8, 8).unwrap()
  let s = p.sheets[0]
  p.sheets[0] = {
    signature: s.signature,
    depth: s.depth,
    front: { left: s.front.right, right: s.front.left, rotation: 0, },
    back: s.back,
  }
  assert_true(verify(p) is Err(CorruptPlan(_)))
  p.sheets.clear()
  assert_eq(verify(p), Err(CorruptPlan("sheet count")))
}
