///|
pub(all) struct WorkflowError {
  field : String
  message : String
} derive(Eq, Debug)

///|
fn workflow_error(field : String, message : String) -> WorkflowError {
  { field, message, }
}

///|
pub extend WorkflowError with Eq::{equal, not_equal}

///|
pub extend WorkflowError with Debug::{to_repr}

///|
fn selection_space(text : String, start : Int32) -> Int32 {
  let mut i = start
  while i < text.length() {
    match text[i] {
      32 | 9 | 10 | 13 => i += 1
      _ => break
    }
  }
  i
}

///|
fn selection_number(
  text : String,
  start : Int32,
) -> Result[(Int32, Int32), WorkflowError] {
  let mut i = start
  let mut value = 0
  while i < text.length() && text[i] >= 48 && text[i] <= 57 {
    value = value * 10 + text[i].to_int() - 48
    if value > 100000 {
      return Err(workflow_error("selection[\{start}]", "page exceeds 100000"))
    }
    i += 1
  }
  if i == start || value == 0 {
    return Err(
      workflow_error("selection[\{start}]", "expected a positive page number"),
    )
  }
  Ok((value, i))
}

///|
/// Comma-separated page numbers, ascending/descending inclusive ranges and `b`.
/// Order and duplicates are intentional. Offsets are UTF-16 code-unit indices.
pub fn parse_selection(
  text : String,
  source_pages : Int32,
) -> Result[Array[Slot], WorkflowError] {
  if source_pages < 1 || source_pages > 100000 {
    return Err(workflow_error("source_pages", "expected 1..100000"))
  }
  if text.length() > 1000000 {
    return Err(workflow_error("selection", "input exceeds 1000000 code units"))
  }
  let pages : Array[Slot] = []
  let mut i = selection_space(text, 0)
  while i < text.length() {
    if text[i] == 98 {
      pages.push(Blank)
      i += 1
    } else {
      let (first, end) = match selection_number(text, i) {
        Ok(pair) => pair
        Err(e) => return Err(e)
      }
      i = selection_space(text, end)
      let mut last = first
      if i < text.length() && text[i] == 45 {
        i = selection_space(text, i + 1)
        let (number, end) = match selection_number(text, i) {
          Ok(pair) => pair
          Err(e) => return Err(e)
        }
        last = number
        i = end
      }
      if first > source_pages || last > source_pages {
        return Err(
          workflow_error("selection[\{i}]", "page outside source document"),
        )
      }
      let count = if first <= last {
        last - first + 1
      } else {
        first - last + 1
      }
      if pages.length() + count > 100000 {
        return Err(
          workflow_error("selection", "expanded selection exceeds 100000 slots"),
        )
      }
      let step = if first <= last { 1 } else { -1 }
      for offset in 0..<count {
        pages.push(Page(first + offset * step))
      }
    }
    if pages.length() > 100000 {
      return Err(
        workflow_error("selection", "expanded selection exceeds 100000 slots"),
      )
    }
    i = selection_space(text, i)
    if i == text.length() {
      break
    }
    if text[i] != 44 {
      return Err(workflow_error("selection[\{i}]", "expected a comma"))
    }
    i = selection_space(text, i + 1)
    if i == text.length() {
      return Err(workflow_error("selection[\{i}]", "missing item after comma"))
    }
  }
  if pages.is_empty() {
    return Err(workflow_error("selection", "selection is empty"))
  }
  Ok(pages)
}
