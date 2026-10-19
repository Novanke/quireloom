///|
fn json_record(fields : Array[(String, Json)]) -> Json {
  Json::object(Map(fields))
}

///|
fn content_json(page : ContentPage) -> Json {
  match page {
    Empty => Json::null()
    Source(source, number) =>
      json_record([
        ("source", Json::string(source)),
        ("page", Json::Json(number)),
      ])
  }
}

///|
/// Canonical, escaped request serialization. Reparse to reproduce the same job.
pub fn job_spec_json(spec : JobSpec) -> Result[String, WorkflowError] {
  match build_job(spec) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let sections = spec.sections.map(fn(section) {
    json_record([
      ("source", Json::string(section.source)),
      ("source_pages", Json::Json(section.source_pages)),
      ("selection", Json::string(section.selection)),
      ("start_on_recto", Json::boolean(section.start_on_recto)),
    ])
  })
  let print = Map([
    ("copies", Json::Json(spec.print.copies)),
    ("reverse_sheets", Json::boolean(spec.print.reverse_sheets)),
    (
      "collation",
      Json::string(
        match spec.print.collation {
          Collated => "collated"
          Uncollated => "uncollated"
        },
      ),
    ),
  ])
  match spec.print.mode {
    Automatic => print.set("mode", Json::string("automatic"))
    Manual(stack) => {
      print.set("mode", Json::string("manual"))
      print.set(
        "back_stack",
        Json::string(
          match stack {
            SameOrder => "same"
            Reversed => "reversed"
          },
        ),
      )
    }
  }
  let fields = Map([
    ("schema", Json::Json(1)),
    ("sections", Json::array(sections)),
    (
      "binding",
      Json::string(if spec.binding == Left { "left" } else { "right" }),
    ),
    (
      "duplex",
      Json::string(
        if spec.duplex == LongEdge {
          "long-edge"
        } else {
          "short-edge"
        },
      ),
    ),
    (
      "paper",
      json_record([
        ("width", Json::Json(spec.paper.width)),
        ("height", Json::Json(spec.paper.height)),
        ("margin", Json::Json(spec.paper.margin)),
        ("gutter", Json::Json(spec.paper.gutter)),
        ("creep", Json::Json(spec.paper.creep)),
      ]),
    ),
    ("print", Json::object(print)),
  ])
  match spec.capacities {
    Some(sizes) =>
      fields.set("gatherings", Json::array(sizes.map(fn(n) { Json::Json(n) })))
    None => {
      fields.set("maximum", Json::Json(spec.maximum))
      fields.set(
        "policy",
        Json::string(
          match spec.policy {
            Fill => "fill"
            Balanced => "balanced"
          },
        ),
      )
    }
  }
  Ok(Json::object(fields).stringify(indent=2))
}

///|
fn resolved_slot(booklet : Booklet, slot : Slot) -> Json {
  match slot {
    Blank =>
      json_record([
        ("logical", Json::null()),
        ("content", Json::null()),
        ("padding", Json::boolean(true)),
      ])
    Page(n) =>
      json_record([
        ("logical", Json::Json(n)),
        ("content", content_json(booklet.document.pages[n - 1])),
        ("padding", Json::boolean(false)),
      ])
  }
}

///|
/// Resolved manifest records source provenance and actual print-pass order.
pub fn job_manifest(job : PrintJob) -> Result[String, WorkflowError] {
  match verify_schedule(job.booklet, job.schedule) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let report = match preflight(job.booklet, job.paper) {
    Err(e) => return Err(e)
    Ok(report) => report
  }
  let faces : Array[Json] = []
  for index, sheet in job.booklet.sheets {
    for side, face in [sheet.front, sheet.back] {
      faces.push(
        json_record([
          ("sheet", Json::Json(index + 1)),
          ("gathering", Json::Json(sheet.signature + 1)),
          ("depth", Json::Json(sheet.depth)),
          ("back", Json::boolean(side == 1)),
          ("rotation", Json::Json(face.rotation)),
          ("left", resolved_slot(job.booklet, face.left)),
          ("right", resolved_slot(job.booklet, face.right)),
        ]),
      )
    }
  }
  let passes = job.schedule.passes.map(fn(pass) {
    json_record([
      ("reload", Json::boolean(pass.reload)),
      (
        "impressions",
        Json::array(
          pass.impressions.map(fn(i) {
            json_record([
              ("copy", Json::Json(i.copy)),
              ("sheet", Json::Json(i.sheet + 1)),
              ("back", Json::boolean(i.back)),
            ])
          }),
        ),
      ),
    ])
  })
  let result = json_record([
    ("schema", Json::Json(1)),
    ("logical_pages", Json::Json(report.logical_pages)),
    ("content_pages", Json::Json(report.content_pages)),
    ("explicit_blanks", Json::Json(report.explicit_blanks)),
    ("padding_blanks", Json::Json(report.padding_blanks)),
    ("physical_sheets", Json::Json(report.sheets * job.schedule.options.copies)),
    ("faces", Json::array(faces)),
    ("passes", Json::array(passes)),
    (
      "issues",
      Json::array(
        report.issues.map(fn(i) {
          json_record([
            ("blocking", Json::boolean(i.blocking)),
            ("field", Json::string(i.field)),
            ("message", Json::string(i.message)),
          ])
        }),
      ),
    ),
  ])
  Ok(result.stringify(indent=2))
}

///|
fn csv_quote(value : String) -> String {
  "\"" + value.replace(old="\"", new="\"\"") + "\""
}

///|
fn slot_csv(booklet : Booklet, slot : Slot) -> String {
  match slot {
    Blank => ",,,true"
    Page(n) =>
      match booklet.document.pages[n - 1] {
        Empty => "\{n},,,false"
        Source(source, page) => "\{n},\{csv_quote(source)},\{page},false"
      }
  }
}

///|
/// One record per impression, with RFC-style quoting for arbitrary source labels.
pub fn job_csv(job : PrintJob) -> Result[String, WorkflowError] {
  match verify_schedule(job.booklet, job.schedule) {
    Err(e) => return Err(e)
    Ok(_) => ()
  }
  let rows = [
    "pass,copy,sheet,gathering,depth,face,left_logical,left_source,left_page,left_padding,right_logical,right_source,right_page,right_padding,rotation",
  ]
  for pass_index, pass in job.schedule.passes {
    for impression in pass.impressions {
      let sheet = job.booklet.sheets[impression.sheet]
      let face = if impression.back { sheet.back } else { sheet.front }
      let side = if impression.back { "back" } else { "front" }
      rows.push(
        "\{pass_index + 1},\{impression.copy},\{impression.sheet + 1},\{sheet.signature + 1},\{sheet.depth},\{side},\{slot_csv(job.booklet, face.left)},\{slot_csv(job.booklet, face.right)},\{face.rotation}",
      )
    }
  }
  Ok(rows.join("\n") + "\n")
}
