///|
#cfg(target="js")
fn runtime_prefix() -> Int32 {
  2
}

///|
#cfg(not(target="js"))
fn runtime_prefix() -> Int32 {
  1
}

///|
fn main {
  let all = @env.args()
  let args : Array[String] = []
  for index in runtime_prefix()..<all.length() {
    args.push(all[index])
  }
  println(@lib.run_command(args).unwrap())
}
