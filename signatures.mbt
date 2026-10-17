///|
/// Split a book into sequential gatherings, padding only the final one to four.
pub fn signatures(
  pages : Int32,
  maximum : Int32,
) -> Result[Array[Signature], PlanError] {
  match validate_config(pages, maximum) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let result : Array[Signature] = []
  let mut start = 1
  let mut remaining = pages
  while remaining > 0 {
    let real_pages = if remaining < maximum { remaining } else { maximum }
    let padded = (real_pages + 3) / 4 * 4
    result.push({ index: result.length(), start, pages: padded, real_pages, })
    start += real_pages
    remaining -= real_pages
  }
  Ok(result)
}
