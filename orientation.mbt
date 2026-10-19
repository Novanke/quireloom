///|
fn mirror(face : Face) -> Face {
  { left: face.right, right: face.left, rotation: face.rotation, }
}

///|
/// A short-edge back is the complete canonical back rotated by 180 degrees.
pub fn impose_with(
  pages : Int32,
  maximum : Int32,
  binding : Binding,
  duplex : Duplex,
) -> Result[Plan, PlanError] {
  let canonical = match impose(pages, maximum) {
    Err(e) => return Err(e)
    Ok(p) => p
  }
  let sheets = canonical.sheets.map(fn(sheet) {
    oriented_sheet(sheet, binding, duplex)
  })
  Ok({ page_count: pages, signature_pages: maximum, binding, duplex, sheets, })
}
