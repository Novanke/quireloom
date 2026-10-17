///|
/// 2048 page-count / gathering / orientation combinations exercise fold invariants.
test "exhaustive small booklet page conservation and folded order" {
  let mut cases = 0
  for pages in 1..<=128 {
    for maximum in [4, 8, 16, 32] {
      for binding in [Left, Right] {
        for duplex in [LongEdge, ShortEdge] {
          let p = impose_with(pages, maximum, binding, duplex).unwrap()
          assert_eq(verify(p), Ok(()))
          let seen = Array::make(pages + 1, 0)
          let mut blanks = 0
          for sheet in p.sheets {
            for
              s in [
                sheet.front.left,
                sheet.front.right,
                sheet.back.left,
                sheet.back.right,
              ] {
              match s {
                Blank => blanks += 1
                Page(n) => seen[n] += 1
              }
            }
          }
          for n in 1..<=pages {
            assert_eq(seen[n], 1)
          }
          assert_eq(p.sheets.length(), (pages + 3) / 4)
          assert_eq(blanks, (4 - pages % 4) % 4)
          cases += 1
        }
      }
    }
  }
  assert_eq(cases, 2048)
}

///|
test "wrong rotations and nesting order are rejected" {
  let p = impose_with(8, 8, Left, ShortEdge).unwrap()
  let s = p.sheets[0]
  p.sheets[0] = {
    signature: 0,
    depth: 0,
    front: s.front,
    back: { left: s.back.left, right: s.back.right, rotation: 0, },
  }
  assert_eq(verify(p), Err(CorruptPlan("face rotation")))
  let p = impose(8, 8).unwrap()
  let s = p.sheets[0]
  p.sheets[0] = p.sheets[1]
  p.sheets[1] = s
  assert_eq(verify(p), Err(CorruptPlan("gathering or nesting order")))
}

///|
test "maximum supported book has bounded exact arithmetic" {
  let p = impose_with(100000, 128, Right, ShortEdge).unwrap()
  assert_eq(p.sheets.length(), 25000)
  assert_eq(verify(p), Ok(()))
}
