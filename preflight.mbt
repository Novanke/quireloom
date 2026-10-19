///|
pub(all) struct Placement {
  logical_page : Int32
  sheet : Int32
  back : Bool
  right : Bool
  rotation : Int32
}

///|
pub(all) struct PreflightIssue {
  blocking : Bool
  field : String
  message : String
}

///|
pub(all) struct Preflight {
  logical_pages : Int32
  content_pages : Int32
  explicit_blanks : Int32
  padding_blanks : Int32
  sheets : Int32
  gatherings : Int32
  repeated_references : Int32
  issues : Array[PreflightIssue]
}

///|
/// Locate every use of a source page, including repeated selections.
pub fn locate_source(
  booklet : Booklet,
  source : String,
  number : Int32,
) -> Result[Array[Placement], WorkflowError] {
  match recover_booklet(booklet) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  if source.is_blank() || number < 1 || number > 100000 {
    return Err(workflow_error("source", "invalid lookup reference"))
  }
  let result : Array[Placement] = []
  for sheet_index, sheet in booklet.sheets {
    for back, face in [sheet.front, sheet.back] {
      for right, slot in [face.left, face.right] {
        match slot {
          Page(n) =>
            if booklet.document.pages[n - 1] == Source(source, number) {
              result.push({
                logical_page: n,
                sheet: sheet_index,
                back: back == 1,
                right: right == 1,
                rotation: face.rotation,
              })
            }
          Blank => ()
        }
      }
    }
  }
  Ok(result)
}

///|
/// Structural errors return Err; paper and content advisories are collected.
/// A repeated reference is an advisory because selection duplication is allowed.
pub fn preflight(
  booklet : Booklet,
  paper : Paper,
) -> Result[Preflight, WorkflowError] {
  match recover_booklet(booklet) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let issues : Array[PreflightIssue] = []
  let mut content_pages = 0
  let mut repeated_references = 0
  let references : Map[(String, Int32), Bool] = Map([])
  for page in booklet.document.pages {
    match page {
      Source(source, number) => {
        content_pages += 1
        let key = (source, number)
        if references.contains(key) {
          repeated_references += 1
        }
        references.set(key, true)
      }
      Empty => ()
    }
  }
  if repeated_references > 0 {
    issues.push({
      blocking: false,
      field: "document",
      message: "\{repeated_references} repeated source references; confirm selection intent",
    })
  }
  if content_pages == 0 {
    issues.push({
      blocking: false,
      field: "document",
      message: "all logical pages are blank",
    })
  }
  for index, sheet in booklet.sheets {
    match layout(paper, sheet.depth) {
      Err(_) =>
        issues.push({
          blocking: true,
          field: "sheets[\{index}].geometry",
          message: "panels clip overlap or have invalid dimensions",
        })
      Ok(_) => ()
    }
  }
  let logical_pages = booklet.document.pages.length()
  let padding_blanks = booklet.sheets.length() * 4 - logical_pages
  if padding_blanks > logical_pages {
    issues.push({
      blocking: false,
      field: "gatherings",
      message: "padding occupies more than half the printed slots",
    })
  }
  Ok({
    logical_pages,
    content_pages,
    explicit_blanks: logical_pages - content_pages,
    padding_blanks,
    sheets: booklet.sheets.length(),
    gatherings: booklet.gatherings.length(),
    repeated_references,
    issues,
  })
}
