///|
fn slot_number(slot : Slot, blank : String) -> String {
  match slot {
    Page(n) => n.to_string()
    Blank => blank
  }
}

///|
fn face_json(face : Face) -> String {
  "{\"left\":\{slot_number(face.left, "null")},\"right\":\{slot_number(face.right, "null")},\"rotation\":\{face.rotation}}"
}

///|
/// Only fixed field names and checked integers enter JSON, so no raw text escapes.
pub fn json_report(plan : Plan) -> Result[String, PlanError] {
  match verify(plan) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let sheets = plan.sheets
    .map(fn(s) {
      "{\"signature\":\{s.signature + 1},\"depth\":\{s.depth},\"front\":\{face_json(s.front)},\"back\":\{face_json(s.back)}}"
    })
    .join(",")
  let binding = if plan.binding == Left { "left" } else { "right" }
  let duplex = if plan.duplex == LongEdge { "long-edge" } else { "short-edge" }
  Ok(
    "{\"page_count\":\{plan.page_count},\"binding\":\"\{binding}\",\"duplex\":\"\{duplex}\",\"sheets\":[\{sheets}]}",
  )
}

///|
/// Each row is one face, with empty fields for deliberate blanks.
pub fn csv_report(plan : Plan) -> Result[String, PlanError] {
  match verify(plan) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let rows = ["signature,depth,face,left,right,rotation"]
  for s in plan.sheets {
    rows.push(
      "\{s.signature + 1},\{s.depth},front,\{slot_number(s.front.left, "")},\{slot_number(s.front.right, "")},\{s.front.rotation}",
    )
    rows.push(
      "\{s.signature + 1},\{s.depth},back,\{slot_number(s.back.left, "")},\{slot_number(s.back.right, "")},\{s.back.rotation}",
    )
  }
  Ok(rows.join("\n") + "\n")
}
