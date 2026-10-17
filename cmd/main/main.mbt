///|
/// Three reproducible publishing scenarios, with no filesystem or network input.
fn main {
  let scenarios : Array[(String, Int32, Int32, @lib.Binding, @lib.Duplex)] = [
    ("Student zine: 15 pages, one gathering", 15, 16, Left, LongEdge),
    ("Teaching workbook: 35 pages, three gatherings", 35, 16, Left, ShortEdge),
    ("Right-bound art booklet: 23 pages", 23, 12, Right, LongEdge),
  ]
  for (title, pages, maximum, binding, duplex) in scenarios {
    let plan = @lib.impose_with(pages, maximum, binding, duplex).unwrap()
    @lib.verify(plan).unwrap()
    println(title)
    println(@lib.csv_report(plan).unwrap())
  }
}
