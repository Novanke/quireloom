///|
pub(all) struct JobSpec {
  sections : Array[Section]
  maximum : Int32
  policy : SignaturePolicy
  capacities : Array[Int32]?
  binding : Binding
  duplex : Duplex
  paper : Paper
  print : PrintOptions
}

///|
pub(all) struct PrintJob {
  booklet : Booklet
  paper : Paper
  schedule : PrintSchedule
}

///|
priv suberror JobDecode {
  JobDecode(WorkflowError)
}

///|
fn decode_fail(path : String, message : String) -> Unit raise JobDecode {
  raise JobDecode(workflow_error(path, message))
}

///|
fn read_object(
  value : Json,
  path : String,
  allowed : Array[String],
) -> Map[String, Json] raise JobDecode {
  let fields = match value {
    Object(fields) => fields
    _ => {
      decode_fail(path, "expected an object")
      Map([])
    }
  }
  for key, _ in fields {
    if !allowed.contains(key) {
      decode_fail(path + "." + key, "unknown field")
    }
  }
  fields
}

///|
fn required(
  fields : Map[String, Json],
  key : String,
  path : String,
) -> Json raise JobDecode {
  match fields.get(key) {
    Some(value) => value
    None => {
      decode_fail(path + "." + key, "required field missing")
      Json::null()
    }
  }
}

///|
fn read_integer(
  value : Json,
  low : Int32,
  high : Int32,
  path : String,
) -> Int32 raise JobDecode {
  match value {
    Number(number, ..) => {
      if number < low.to_double() || number > high.to_double() {
        decode_fail(path, "integer outside \{low}..\{high}")
      }
      let integer = number.to_int()
      if integer.to_double() != number {
        decode_fail(path, "expected a whole number")
      }
      integer
    }
    _ => {
      decode_fail(path, "expected an integer")
      0
    }
  }
}

///|
fn integer_field(
  fields : Map[String, Json],
  key : String,
  fallback : Int32?,
  low : Int32,
  high : Int32,
  path : String,
) -> Int32 raise JobDecode {
  match (fields.get(key), fallback) {
    (Some(value), _) => read_integer(value, low, high, path + "." + key)
    (None, Some(value)) => value
    (None, None) => {
      decode_fail(path + "." + key, "required integer missing")
      0
    }
  }
}

///|
fn text_field(
  fields : Map[String, Json],
  key : String,
  fallback : String?,
  path : String,
) -> String raise JobDecode {
  match (fields.get(key), fallback) {
    (Some(String(value)), _) => value
    (None, Some(value)) => value
    _ => {
      decode_fail(path + "." + key, "expected a string")
      ""
    }
  }
}

///|
fn bool_field(
  fields : Map[String, Json],
  key : String,
  fallback : Bool,
  path : String,
) -> Bool raise JobDecode {
  match fields.get(key) {
    Some(True) => true
    Some(False) => false
    None => fallback
    _ => {
      decode_fail(path + "." + key, "expected a boolean")
      false
    }
  }
}

///|
fn decode_job(value : Json) -> JobSpec raise JobDecode {
  let root = read_object(value, "$", [
    "schema", "sections", "maximum", "policy", "gatherings", "binding", "duplex",
    "paper", "print",
  ])
  let _schema = integer_field(root, "schema", Some(1), 1, 1, "$")
  let sections : Array[Section] = []
  let items = match required(root, "sections", "$") {
    Array(items) => items
    _ => {
      decode_fail("$.sections", "expected an array")
      []
    }
  }
  if items.is_empty() || items.length() > 1000 {
    decode_fail("$.sections", "expected 1..1000 sections")
  }
  for index, item in items {
    let path = "$.sections[\{index}]"
    let fields = read_object(item, path, [
      "source", "source_pages", "selection", "start_on_recto",
    ])
    sections.push({
      source: text_field(fields, "source", None, path),
      source_pages: integer_field(fields, "source_pages", None, 1, 100000, path),
      selection: text_field(fields, "selection", None, path),
      start_on_recto: bool_field(fields, "start_on_recto", false, path),
    })
  }
  let maximum = integer_field(root, "maximum", Some(16), 4, 128, "$")
  let policy = match text_field(root, "policy", Some("balanced"), "$") {
    "fill" => Fill
    "balanced" => Balanced
    _ => {
      decode_fail("$.policy", "expected fill or balanced")
      Fill
    }
  }
  let capacities = match root.get("gatherings") {
    None => None
    Some(Array(items)) => {
      if root.contains("maximum") || root.contains("policy") {
        decode_fail(
          "$.gatherings", "cannot combine explicit gatherings with maximum or policy",
        )
      }
      if items.is_empty() || items.length() > 25000 {
        decode_fail("$.gatherings", "expected 1..25000 capacities")
      }
      let sizes : Array[Int32] = []
      for index, item in items {
        sizes.push(read_integer(item, 4, 128, "$.gatherings[\{index}]"))
      }
      Some(sizes)
    }
    _ => {
      decode_fail("$.gatherings", "expected an array")
      None
    }
  }
  let binding = match text_field(root, "binding", Some("left"), "$") {
    "left" => Left
    "right" => Right
    _ => {
      decode_fail("$.binding", "expected left or right")
      Left
    }
  }
  let duplex = match text_field(root, "duplex", Some("long-edge"), "$") {
    "long-edge" => LongEdge
    "short-edge" => ShortEdge
    _ => {
      decode_fail("$.duplex", "expected long-edge or short-edge")
      LongEdge
    }
  }
  let p = read_object(required(root, "paper", "$"), "$.paper", [
    "width", "height", "margin", "gutter", "creep",
  ])
  let paper : Paper = {
    width: integer_field(p, "width", None, 1, 10000, "$.paper"),
    height: integer_field(p, "height", None, 1, 10000, "$.paper"),
    margin: integer_field(p, "margin", Some(10), 0, 10000, "$.paper"),
    gutter: integer_field(p, "gutter", Some(0), 0, 10000, "$.paper"),
    creep: integer_field(p, "creep", Some(0), 0, 1000, "$.paper"),
  }
  let print = read_object(
    root.get("print").unwrap_or(Json::empty_object()),
    "$.print",
    ["copies", "reverse_sheets", "collation", "mode", "back_stack"],
  )
  let collation = match
    text_field(print, "collation", Some("collated"), "$.print") {
    "collated" => Collated
    "uncollated" => Uncollated
    _ => {
      decode_fail("$.print.collation", "expected collated or uncollated")
      Collated
    }
  }
  let mode = match text_field(print, "mode", Some("automatic"), "$.print") {
    "automatic" => {
      if print.contains("back_stack") {
        decode_fail("$.print.back_stack", "only valid for manual printing")
      }
      Automatic
    }
    "manual" =>
      Manual(
        match text_field(print, "back_stack", Some("reversed"), "$.print") {
          "same" => SameOrder
          "reversed" => Reversed
          _ => {
            decode_fail("$.print.back_stack", "expected same or reversed")
            Reversed
          }
        },
      )
    _ => {
      decode_fail("$.print.mode", "expected automatic or manual")
      Automatic
    }
  }
  {
    sections,
    maximum,
    policy,
    capacities,
    binding,
    duplex,
    paper,
    print: {
      copies: integer_field(print, "copies", Some(1), 1, 1000, "$.print"),
      reverse_sheets: bool_field(print, "reverse_sheets", false, "$.print"),
      collation,
      mode,
    },
  }
}

///|
#warnings("-deprecated")
pub fn parse_job(text : String) -> Result[JobSpec, WorkflowError] {
  if text.length() > 2000000 {
    return Err(workflow_error("$", "job input exceeds 2000000 code units"))
  }
  let value = @json.parse(text, max_nesting_depth=32) catch {
    _ => return Err(workflow_error("$", "invalid JSON or nesting exceeds 32"))
  }
  Ok(decode_job(value)) catch {
    JobDecode(error) => Err(error)
  }
}

///|
/// Compile a request only when the document, imposition, geometry and schedule pass.
pub fn build_job(spec : JobSpec) -> Result[PrintJob, WorkflowError] {
  let document = match assemble_document(spec.sections) {
    Ok(doc) => doc
    Err(e) => return Err(e)
  }
  let groups = match
    (match spec.capacities {
      Some(sizes) => explicit_gatherings(document.pages.length(), sizes)
      None =>
        plan_gatherings(document.pages.length(), spec.maximum, spec.policy)
    }) {
    Ok(groups) => groups
    Err(e) => return Err(e)
  }
  let booklet = match
    impose_document(document, groups, spec.binding, spec.duplex) {
    Ok(booklet) => booklet
    Err(e) => return Err(e)
  }
  let check = match preflight(booklet, spec.paper) {
    Ok(report) => report
    Err(e) => return Err(e)
  }
  for issue in check.issues {
    if issue.blocking {
      return Err(workflow_error(issue.field, issue.message))
    }
  }
  let schedule = match schedule_print(booklet, spec.print) {
    Ok(schedule) => schedule
    Err(e) => return Err(e)
  }
  match verify_schedule(booklet, schedule) {
    Ok(_) => ()
    Err(e) => return Err(e)
  }
  Ok({ booklet, paper: spec.paper, schedule, })
}
