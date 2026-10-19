///|
pub(all) struct Booklet {
  document : Document
  gatherings : Array[Signature]
  sheets : Array[Sheet]
  binding : Binding
  duplex : Duplex
}

///|
fn oriented_sheet(sheet : Sheet, binding : Binding, duplex : Duplex) -> Sheet {
  let front = if binding == Right { mirror(sheet.front) } else { sheet.front }
  let back = if binding == Right { mirror(sheet.back) } else { sheet.back }
  let back = if duplex == ShortEdge {
    { left: back.right, right: back.left, rotation: 180, }
  } else {
    back
  }
  { signature: sheet.signature, depth: sheet.depth, front, back, }
}

///|
/// Impose logical positions, keeping the source map separate from padding.
pub fn impose_document(
  document : Document,
  gatherings : Array[Signature],
  binding : Binding,
  duplex : Duplex,
) -> Result[Booklet, WorkflowError] {
  match validate_document(document) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  match validate_gatherings(document.pages.length(), gatherings) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let sheets : Array[Sheet] = []
  for group in gatherings {
    let last = group.start + group.pages - 1
    for depth in 0..<(group.pages / 4) {
      let low = group.start + 2 * depth
      let high = last - 2 * depth
      let sheet : Sheet = {
        signature: group.index,
        depth,
        front: {
          left: slot(high, document.pages.length()),
          right: slot(low, document.pages.length()),
          rotation: 0,
        },
        back: {
          left: slot(low + 1, document.pages.length()),
          right: slot(high - 1, document.pages.length()),
          rotation: 0,
        },
      }
      sheets.push(oriented_sheet(sheet, binding, duplex))
    }
  }
  Ok({ document, gatherings, sheets, binding, duplex, })
}

///|
/// Consume the supplied faces instead of reimposing a fresh plan for comparison.
pub fn recover_booklet(
  booklet : Booklet,
) -> Result[Array[ContentPage], WorkflowError] {
  match validate_document(booklet.document) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let count = booklet.document.pages.length()
  match validate_gatherings(count, booklet.gatherings) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  if booklet.sheets.length() != (count + 3) / 4 {
    return Err(workflow_error("sheets", "incorrect sheet count"))
  }
  let order : Array[Slot] = []
  let mut cursor = 0
  for group in booklet.gatherings {
    let fronts : Array[Face] = []
    let backs : Array[Face] = []
    for depth in 0..<(group.pages / 4) {
      let sheet = booklet.sheets[cursor]
      let field = "sheets[\{cursor}]"
      cursor += 1
      if sheet.signature != group.index || sheet.depth != depth {
        return Err(
          workflow_error(field, "incorrect gathering or nesting order"),
        )
      }
      let rotation = if booklet.duplex == ShortEdge { 180 } else { 0 }
      if sheet.front.rotation != 0 || sheet.back.rotation != rotation {
        return Err(workflow_error(field, "incorrect face rotation"))
      }
      let back = if booklet.duplex == ShortEdge {
        mirror(sheet.back)
      } else {
        sheet.back
      }
      fronts.push(
        if booklet.binding == Right {
          mirror(sheet.front)
        } else {
          sheet.front
        },
      )
      backs.push(if booklet.binding == Right { mirror(back) } else { back })
    }
    for depth in 0..<fronts.length() {
      order.push(fronts[depth].right)
      order.push(backs[depth].left)
    }
    let mut depth = fronts.length() - 1
    while depth >= 0 {
      order.push(backs[depth].right)
      order.push(fronts[depth].left)
      depth -= 1
    }
  }
  let result : Array[ContentPage] = []
  for index, position in order {
    let expected = if index < count { Page(index + 1) } else { Blank }
    if position != expected {
      return Err(
        workflow_error(
          "folded[\{index + 1}]",
          "incorrect logical page or padding",
        ),
      )
    }
    result.push(
      match position {
        Page(n) => booklet.document.pages[n - 1]
        Blank => Empty
      },
    )
  }
  Ok(result)
}
