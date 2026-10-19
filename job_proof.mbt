///|
fn xml_text(value : String) -> String {
  let out = StringBuilder()
  for c in value.iter() {
    match c {
      '&' => out.write_string("&amp;")
      '<' => out.write_string("&lt;")
      '>' => out.write_string("&gt;")
      '"' => out.write_string("&quot;")
      '\'' => out.write_string("&apos;")
      '\n' | '\r' | '\t' => out.write_char(' ')
      _ =>
        if c.to_int() < 32 || c == '\u{FFFE}' || c == '\u{FFFF}' {
          out.write_char('�')
        } else {
          out.write_char(c)
        }
    }
  }
  out.to_string()
}

///|
fn content_panel(
  rect : Rect,
  booklet : Booklet,
  slot : Slot,
  rotation : Int32,
) -> String {
  let (logical, label) = match slot {
    Blank => ("PADDING", "No source page")
    Page(n) =>
      (
        "Logical \{n}",
        match booklet.document.pages[n - 1] {
          Empty => "AUTHORED BLANK"
          Source(source, page) => "\{source} #\{page}"
        },
      )
  }
  let cx = rect.x + rect.width / 2
  let cy = rect.y + rect.height / 2
  "<rect x=\"\{rect.x}\" y=\"\{rect.y}\" width=\"\{rect.width}\" height=\"\{rect.height}\" fill=\"#f4f6f3\" stroke=\"#24453b\" stroke-width=\"0.4\"/><svg x=\"\{rect.x}\" y=\"\{rect.y}\" width=\"\{rect.width}\" height=\"\{rect.height}\" viewBox=\"\{rect.x} \{rect.y} \{rect.width} \{rect.height}\"><g transform=\"rotate(\{rotation} \{cx} \{cy})\"><text x=\"\{cx}\" y=\"\{cy}\" text-anchor=\"middle\" font-family=\"sans-serif\" font-size=\"7\">\{xml_text(logical)}</text><text x=\"\{cx}\" y=\"\{cy + 8}\" text-anchor=\"middle\" font-family=\"sans-serif\" font-size=\"4\">\{xml_text(label)}</text></g></svg>"
}

///|
fn job_face_svg(
  job : PrintJob,
  sheet_index : Int32,
  back : Bool,
) -> Result[String, WorkflowError] {
  let sheet = job.booklet.sheets[sheet_index]
  let positions = match layout(job.paper, sheet.depth) {
    Ok(positions) => positions
    Err(_) =>
      return Err(
        workflow_error("paper", "invalid geometry for requested sheet"),
      )
  }
  let face = if back { sheet.back } else { sheet.front }
  let left = content_panel(
    positions.left,
    job.booklet,
    face.left,
    face.rotation,
  )
  let right = content_panel(
    positions.right,
    job.booklet,
    face.right,
    face.rotation,
  )
  let center = job.paper.width / 2
  Ok(
    "<rect width=\"100%\" height=\"100%\" fill=\"white\"/>\{left}\{right}<path d=\"M \{center} 0 V \{job.paper.height}\" fill=\"none\" stroke=\"#cb6744\" stroke-width=\"0.4\" stroke-dasharray=\"2 2\"/>",
  )
}

///|
/// A dimensioned source-labelled proof; source artwork is not embedded.
pub fn job_proof(
  job : PrintJob,
  sheet_index : Int32,
  back : Bool,
) -> Result[String, WorkflowError] {
  match recover_booklet(job.booklet) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  if sheet_index < 0 || sheet_index >= job.booklet.sheets.length() {
    return Err(workflow_error("sheet", "proof sheet index out of range"))
  }
  let content = match job_face_svg(job, sheet_index, back) {
    Ok(svg) => svg
    Err(e) => return Err(e)
  }
  let side = if back { "back" } else { "front" }
  Ok(
    "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\{job.paper.width}mm\" height=\"\{job.paper.height}mm\" viewBox=\"0 0 \{job.paper.width} \{job.paper.height}\"><title>QuireLoom sheet \{sheet_index + 1} \{side}</title>\{content}</svg>",
  )
}

///|
/// Paginate large jobs with first_sheet/count; each atlas is limited to 64 sheets.
pub fn proof_atlas(
  job : PrintJob,
  first_sheet : Int32,
  count : Int32,
) -> Result[String, WorkflowError] {
  match verify_schedule(job.booklet, job.schedule) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  if count < 1 ||
    count > 64 ||
    first_sheet < 0 ||
    first_sheet > job.booklet.sheets.length() - count {
    return Err(
      workflow_error("atlas", "expected a valid range containing 1..64 sheets"),
    )
  }
  let width = job.paper.width * 2 + 12
  let row_height = job.paper.height + 16
  let height = row_height * count
  let fragments : Array[String] = []
  for index in first_sheet..<(first_sheet + count) {
    let sheet = job.booklet.sheets[index]
    let y = (index - first_sheet) * row_height
    for side in 0..<2 {
      let x = side * (job.paper.width + 12)
      let label = if side == 0 { "FRONT" } else { "BACK" }
      let content = match job_face_svg(job, index, side == 1) {
        Ok(svg) => svg
        Err(e) => return Err(e)
      }
      fragments.push(
        "<text x=\"\{x}\" y=\"\{y + 7}\" font-family=\"sans-serif\" font-size=\"4\">Sheet \{index + 1} / gathering \{sheet.signature + 1} / depth \{sheet.depth} / \{label}</text><svg x=\"\{x}\" y=\"\{y + 12}\" width=\"\{job.paper.width}\" height=\"\{job.paper.height}\" viewBox=\"0 0 \{job.paper.width} \{job.paper.height}\">\{content}</svg>",
      )
    }
  }
  Ok(
    "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\{width}mm\" height=\"\{height}mm\" viewBox=\"0 0 \{width} \{height}\"><title>QuireLoom source-labelled proof atlas</title><rect width=\"100%\" height=\"100%\" fill=\"#e9eeea\"/>\{fragments.join("")}</svg>",
  )
}
