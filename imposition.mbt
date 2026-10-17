///|
fn slot(number : Int32, total : Int32) -> Slot {
  if number > total {
    Blank
  } else {
    Page(number)
  }
}

///|
/// Sheet order is signature order, then outside to inside.
pub fn impose(pages : Int32, maximum : Int32) -> Result[Plan, PlanError] {
  let groups = match signatures(pages, maximum) {
    Err(e) => return Err(e)
    Ok(groups) => groups
  }
  let sheets : Array[Sheet] = []
  for group in groups {
    let last = group.start + group.pages - 1
    for depth in 0..<(group.pages / 4) {
      let low = group.start + 2 * depth
      let high = last - 2 * depth
      sheets.push({
        signature: group.index,
        depth,
        front: {
          left: slot(high, pages),
          right: slot(low, pages),
          rotation: 0,
        },
        back: {
          left: slot(low + 1, pages),
          right: slot(high - 1, pages),
          rotation: 0,
        },
      })
    }
  }
  Ok({
    page_count: pages,
    signature_pages: maximum,
    binding: Left,
    duplex: LongEdge,
    sheets,
  })
}
