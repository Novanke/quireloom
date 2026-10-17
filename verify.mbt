///|
/// Undo print orientation, then traverse folded leaves from outside to inside.
/// This verifier consumes a supplied plan; it does not regenerate an imposition.
pub fn recover(plan : Plan) -> Result[Array[Slot], PlanError] {
  let groups = match signatures(plan.page_count, plan.signature_pages) {
    Err(e) => return Err(e)
    Ok(groups) => groups
  }
  let expected_sheets = (plan.page_count + 3) / 4
  if plan.sheets.length() != expected_sheets {
    return Err(CorruptPlan("sheet count"))
  }
  let recovered : Array[Slot] = []
  let mut cursor = 0
  for group in groups {
    let fronts : Array[Face] = []
    let backs : Array[Face] = []
    for depth in 0..<(group.pages / 4) {
      let sheet = plan.sheets[cursor]
      cursor += 1
      if sheet.signature != group.index || sheet.depth != depth {
        return Err(CorruptPlan("gathering or nesting order"))
      }
      let rotation = if plan.duplex == ShortEdge { 180 } else { 0 }
      if sheet.front.rotation != 0 || sheet.back.rotation != rotation {
        return Err(CorruptPlan("face rotation"))
      }
      let back = if plan.duplex == ShortEdge {
        mirror(sheet.back)
      } else {
        sheet.back
      }
      fronts.push(
        if plan.binding == Right {
          mirror(sheet.front)
        } else {
          sheet.front
        },
      )
      backs.push(if plan.binding == Right { mirror(back) } else { back })
    }
    for depth in 0..<fronts.length() {
      recovered.push(fronts[depth].right)
      recovered.push(backs[depth].left)
    }
    let mut depth = fronts.length() - 1
    while depth >= 0 {
      recovered.push(backs[depth].right)
      recovered.push(fronts[depth].left)
      depth -= 1
    }
  }
  Ok(recovered)
}

///|
/// Require exact reading order, including every final blank.
pub fn verify(plan : Plan) -> Result[Unit, PlanError] {
  let pages = match recover(plan) {
    Err(e) => return Err(e)
    Ok(pages) => pages
  }
  for index in 0..<pages.length() {
    let expected = if index < plan.page_count { Page(index + 1) } else { Blank }
    if pages[index] != expected {
      return Err(CorruptPlan("reading order at slot \{index + 1}"))
    }
  }
  Ok(())
}
