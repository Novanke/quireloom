///|
fn same_physical_sheet(a : Impression, b : Impression) -> Bool {
  a.copy == b.copy && a.sheet == b.sheet
}

///|
/// Check coverage and actual refeed pairings, including externally edited passes.
pub fn verify_schedule(
  booklet : Booklet,
  schedule : PrintSchedule,
) -> Result[Unit, WorkflowError] {
  match recover_booklet(booklet) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let sheets = booklet.sheets.length()
  match validate_print_options(sheets, schedule.options) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let count = sheets * schedule.options.copies
  let expected_passes = match schedule.options.mode {
    Automatic => 1
    Manual(_) => 2
  }
  if schedule.passes.length() != expected_passes {
    return Err(workflow_error("passes", "wrong pass count for print mode"))
  }
  let seen = Array::make(count * 2, false)
  for pass_index, pass in schedule.passes {
    if pass.reload != (pass_index == 1) {
      return Err(
        workflow_error(
          "passes[\{pass_index}].reload",
          "unexpected refeed marker",
        ),
      )
    }
    let length = if expected_passes == 1 { count * 2 } else { count }
    if pass.impressions.length() != length {
      return Err(
        workflow_error("passes[\{pass_index}]", "incorrect impression count"),
      )
    }
    for index, impression in pass.impressions {
      let field = "passes[\{pass_index}][\{index}]"
      if impression.sheet < 0 ||
        impression.sheet >= sheets ||
        impression.copy < 1 ||
        impression.copy > schedule.options.copies {
        return Err(
          workflow_error(field, "out-of-range physical sheet reference"),
        )
      }
      let side = if impression.back { 1 } else { 0 }
      let key = ((impression.copy - 1) * sheets + impression.sheet) * 2 + side
      if seen[key] {
        return Err(workflow_error(field, "duplicate sheet face"))
      }
      seen[key] = true
      match schedule.options.mode {
        Automatic => {
          if impression.back != (index % 2 == 1) {
            return Err(
              workflow_error(
                field, "automatic pass must alternate front and back",
              ),
            )
          }
          if index % 2 == 1 &&
            !same_physical_sheet(impression, pass.impressions[index - 1]) {
            return Err(
              workflow_error(
                field, "automatic duplex faces belong to different sheets",
              ),
            )
          }
        }
        Manual(stack) => {
          if impression.back != (pass_index == 1) {
            return Err(
              workflow_error(field, "manual pass contains the wrong face"),
            )
          }
          if pass_index == 1 {
            let front_index = match stack {
              SameOrder => index
              Reversed => count - 1 - index
            }
            if !same_physical_sheet(
                impression,
                schedule.passes[0].impressions[front_index],
              ) {
              return Err(
                workflow_error(
                  field, "back does not match calibrated refeed order",
                ),
              )
            }
          }
        }
      }
    }
  }
  for printed in seen {
    if !printed {
      return Err(workflow_error("passes", "missing sheet face"))
    }
  }
  let fronts = schedule.passes[0].impressions
  for position in 0..<count {
    let index = if expected_passes == 1 { position * 2 } else { position }
    let impression = fronts[index]
    let (copy, ordinal) = match schedule.options.collation {
      Collated => (position / sheets + 1, position % sheets)
      Uncollated =>
        (
          position % schedule.options.copies + 1,
          position / schedule.options.copies,
        )
    }
    let sheet = if schedule.options.reverse_sheets {
      sheets - 1 - ordinal
    } else {
      ordinal
    }
    if impression.copy != copy || impression.sheet != sheet {
      return Err(
        workflow_error(
          "passes[0][\{index}]",
          "incorrect copy collation or sheet order",
        ),
      )
    }
  }
  Ok(())
}
