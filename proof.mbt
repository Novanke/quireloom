///|
fn panel_svg(rect : Rect, slot : Slot, rotation : Int32) -> String {
  let cx = rect.x + rect.width / 2
  let cy = rect.y + rect.height / 2
  let label = slot_number(slot, "BLANK")
  "<rect x=\"\{rect.x}\" y=\"\{rect.y}\" width=\"\{rect.width}\" height=\"\{rect.height}\" fill=\"#f6f4ed\" stroke=\"#243f3c\" stroke-width=\"0.4\"/><text x=\"\{cx}\" y=\"\{cy}\" text-anchor=\"middle\" font-family=\"sans-serif\" font-size=\"12\" transform=\"rotate(\{rotation} \{cx} \{cy})\">\{label}</text>"
}

///|
/// A proof contains page labels and a fold line, not source PDF artwork.
pub fn svg_proof(
  plan : Plan,
  paper : Paper,
  sheet_index : Int32,
  back : Bool,
) -> Result[String, PlanError] {
  match verify(plan) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  if sheet_index < 0 || sheet_index >= plan.sheets.length() {
    return Err(CorruptPlan("proof sheet index"))
  }
  let sheet = plan.sheets[sheet_index]
  let positions = match layout(paper, sheet.depth) {
    Err(e) => return Err(e)
    Ok(p) => p
  }
  let face = if back { sheet.back } else { sheet.front }
  let side = if back { "BACK" } else { "FRONT" }
  let left = panel_svg(positions.left, face.left, face.rotation)
  let right = panel_svg(positions.right, face.right, face.rotation)
  let center = paper.width / 2
  Ok(
    "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\{paper.width}mm\" height=\"\{paper.height}mm\" viewBox=\"0 0 \{paper.width} \{paper.height}\"><title>QuireLoom gathering \{sheet.signature + 1} depth \{sheet.depth} \{side}</title><rect width=\"100%\" height=\"100%\" fill=\"white\"/>\{left}\{right}<path d=\"M \{center} 0 V \{paper.height}\" stroke=\"#d26b45\" stroke-width=\"0.4\" stroke-dasharray=\"2 2\"/><text x=\"2\" y=\"5\" font-family=\"sans-serif\" font-size=\"3\">Gathering \{sheet.signature + 1} / depth \{sheet.depth} / \{side}</text></svg>",
  )
}
