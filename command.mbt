///|
pub fn command_help() -> String {
  "QuireLoom --job <JSON> [--format manifest|csv|normalize|proof|atlas]\nproof: --sheet <1-based> [--back]\natlas: --first <1-based> --count <1..64>\nInput is inline JSON; use shell file reading to pass a saved job. Output is stdout.\n"
}

///|
fn command_number(
  value : String,
  field : String,
) -> Result[Int32, WorkflowError] {
  match selection_number(value, 0) {
    Ok((number, end)) if end == value.length() => Ok(number)
    _ => Err(workflow_error(field, "expected a decimal integer in 1..100000"))
  }
}

///|
/// Pure command adapter: argv excludes the runtime/program names.
pub fn run_command(args : Array[String]) -> Result[String, WorkflowError] {
  if args.is_empty() || (args.length() == 1 && args[0] == "--help") {
    return Ok(command_help())
  }
  let options : Map[String, String] = Map([])
  let mut index = 0
  while index < args.length() {
    let key = args[index]
    if !["--job", "--format", "--sheet", "--back", "--first", "--count"].contains(
        key,
      ) {
      return Err(workflow_error("argv[\{index}]", "unknown option: " + key))
    }
    if options.contains(key) {
      return Err(workflow_error(key, "duplicate option"))
    }
    if key == "--back" {
      options.set(key, "true")
      index += 1
    } else {
      if index + 1 >= args.length() {
        return Err(workflow_error(key, "missing option value"))
      }
      options.set(key, args[index + 1])
      index += 2
    }
  }
  let text = match options.get("--job") {
    Some(text) => text
    None => return Err(workflow_error("--job", "a JSON job is required"))
  }
  let format = options.get("--format").unwrap_or("manifest")
  if !["manifest", "csv", "normalize", "proof", "atlas"].contains(format) {
    return Err(workflow_error("--format", "unknown output format"))
  }
  for key in ["--sheet", "--back", "--first", "--count"] {
    if options.contains(key) {
      let allowed = if format == "proof" {
        key == "--sheet" || key == "--back"
      } else if format == "atlas" {
        key == "--first" || key == "--count"
      } else {
        false
      }
      if !allowed {
        return Err(
          workflow_error(key, "option does not apply to this output format"),
        )
      }
    }
  }
  let spec = match parse_job(text) {
    Ok(spec) => spec
    Err(e) => return Err(e)
  }
  if format == "normalize" {
    return job_spec_json(spec)
  }
  let job = match build_job(spec) {
    Ok(job) => job
    Err(e) => return Err(e)
  }
  match format {
    "csv" => job_csv(job)
    "proof" => {
      let sheet = match
        command_number(options.get("--sheet").unwrap_or("1"), "--sheet") {
        Ok(n) => n
        Err(e) => return Err(e)
      }
      job_proof(job, sheet - 1, options.contains("--back"))
    }
    "atlas" => {
      let first = match
        command_number(options.get("--first").unwrap_or("1"), "--first") {
        Ok(n) => n
        Err(e) => return Err(e)
      }
      let count = match
        command_number(options.get("--count").unwrap_or("1"), "--count") {
        Ok(n) => n
        Err(e) => return Err(e)
      }
      proof_atlas(job, first - 1, count)
    }
    _ => job_manifest(job)
  }
}
