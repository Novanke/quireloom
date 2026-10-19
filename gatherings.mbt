///|
pub(all) enum SignaturePolicy {
  Fill
  Balanced
}

///|
/// Balanced distributes whole sheets across the fewest possible gatherings.
/// Sizes differ by at most one sheet; padding is still confined to the end.
pub fn plan_gatherings(
  pages : Int32,
  maximum : Int32,
  policy : SignaturePolicy,
) -> Result[Array[Signature], WorkflowError] {
  match validate_config(pages, maximum) {
    Err(_) =>
      return Err(
        workflow_error("gatherings", "invalid page count or maximum capacity"),
      )
    Ok(_) => ()
  }
  match policy {
    Fill =>
      match signatures(pages, maximum) {
        Ok(groups) => Ok(groups)
        Err(_) =>
          Err(
            workflow_error(
              "gatherings", "invalid page count or maximum capacity",
            ),
          )
      }
    Balanced => {
      let sheets = (pages + 3) / 4
      let count = (sheets + maximum / 4 - 1) / (maximum / 4)
      let base = sheets / count
      let extra = sheets % count
      let sizes = Array::makei(count, fn(index) {
        (base + (if index < extra { 1 } else { 0 })) * 4
      })
      explicit_gatherings(pages, sizes)
    }
  }
}

///|
/// Use a binder-specified sequence of gathering capacities, with no empty group.
pub fn explicit_gatherings(
  pages : Int32,
  sizes : Array[Int32],
) -> Result[Array[Signature], WorkflowError] {
  if pages < 1 || pages > 100000 || sizes.is_empty() || sizes.length() > 25000 {
    return Err(
      workflow_error("gatherings", "invalid document length or gathering count"),
    )
  }
  let groups : Array[Signature] = []
  let mut start = 1
  for index, capacity in sizes {
    if capacity < 4 || capacity > 128 || capacity % 4 != 0 {
      return Err(
        workflow_error(
          "gatherings[\{index}]",
          "capacity must be a multiple of four in 4..128",
        ),
      )
    }
    let remaining = pages - start + 1
    if remaining <= 0 {
      return Err(
        workflow_error("gatherings[\{index}]", "empty trailing gathering"),
      )
    }
    let real_pages = if remaining < capacity { remaining } else { capacity }
    if real_pages < capacity - 3 {
      return Err(
        workflow_error(
          "gatherings[\{index}]",
          "excess padding; shrink the final capacity",
        ),
      )
    }
    groups.push({ index, start, pages: capacity, real_pages, })
    start += real_pages
  }
  if start != pages + 1 {
    return Err(
      workflow_error("gatherings", "capacities do not cover the document"),
    )
  }
  Ok(groups)
}

///|
pub fn validate_gatherings(
  pages : Int32,
  groups : Array[Signature],
) -> Result[Unit, WorkflowError] {
  let expected = match
    explicit_gatherings(pages, groups.map(fn(g) { g.pages })) {
    Err(e) => return Err(e)
    Ok(groups) => groups
  }
  for index in 0..<groups.length() {
    if groups[index] != expected[index] {
      return Err(
        workflow_error(
          "gatherings[\{index}]",
          "invalid index start or real page count",
        ),
      )
    }
  }
  Ok(())
}
