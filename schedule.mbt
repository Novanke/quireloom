///|
pub(all) enum BackStack {
  SameOrder
  Reversed
}

///|
pub(all) enum PrintMode {
  Automatic
  Manual(BackStack)
}

///|
pub(all) enum Collation {
  Collated
  Uncollated
}

///|
pub(all) struct PrintOptions {
  copies : Int32
  reverse_sheets : Bool
  collation : Collation
  mode : PrintMode
}

///|
pub(all) struct Impression {
  copy : Int32
  sheet : Int32
  back : Bool
}

///|
pub(all) struct PrintPass {
  reload : Bool
  impressions : Array[Impression]
}

///|
pub(all) struct PrintSchedule {
  options : PrintOptions
  passes : Array[PrintPass]
}

///|
fn validate_print_options(
  sheets : Int32,
  options : PrintOptions,
) -> Result[Unit, WorkflowError] {
  if sheets < 1 || sheets > 25000 || options.copies < 1 || options.copies > 1000 {
    return Err(
      workflow_error("print", "expected 1..25000 sheets and 1..1000 copies"),
    )
  }
  if sheets * options.copies > 100000 {
    return Err(workflow_error("print", "job exceeds 100000 physical sheets"))
  }
  Ok(())
}

///|
/// Schedule explicit impressions. Manual refeed order is chosen by the caller;
/// it expresses a calibrated stack permutation, not a printer-driver promise.
pub fn schedule_print(
  booklet : Booklet,
  options : PrintOptions,
) -> Result[PrintSchedule, WorkflowError] {
  match recover_booklet(booklet) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let count = booklet.sheets.length()
  match validate_print_options(count, options) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let work : Array[Impression] = []
  match options.collation {
    Collated =>
      for copy in 1..<=options.copies {
        for index in 0..<count {
          let sheet = if options.reverse_sheets {
            count - 1 - index
          } else {
            index
          }
          work.push({ copy, sheet, back: false, })
        }
      }
    Uncollated =>
      for index in 0..<count {
        let sheet = if options.reverse_sheets {
          count - 1 - index
        } else {
          index
        }
        for copy in 1..<=options.copies {
          work.push({ copy, sheet, back: false, })
        }
      }
  }
  let passes : Array[PrintPass] = []
  match options.mode {
    Automatic => {
      let impressions : Array[Impression] = []
      for front in work {
        impressions.push(front)
        impressions.push({ ..front, back: true, })
      }
      passes.push({ reload: false, impressions, })
    }
    Manual(stack) => {
      let backs : Array[Impression] = []
      for index in 0..<work.length() {
        let position = match stack {
          SameOrder => index
          Reversed => work.length() - 1 - index
        }
        backs.push({ ..work[position], back: true, })
      }
      passes.push({ reload: false, impressions: work, })
      passes.push({ reload: true, impressions: backs, })
    }
  }
  Ok({ options, passes, })
}
