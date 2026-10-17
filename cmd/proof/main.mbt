///|
/// Redirect stdout to a .svg file to inspect or print a calibration sheet.
fn main {
  let plan = @lib.impose(15, 16).unwrap()
  let paper : @lib.Paper = {
    width: 420,
    height: 297,
    margin: 10,
    gutter: 20,
    creep: 1,
  }
  println(@lib.svg_proof(plan, paper, 0, false).unwrap())
}
