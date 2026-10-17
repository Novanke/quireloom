///|
/// All distances are integer millimetres. Creep means an explicit inward shift.
pub(all) struct Paper {
  width : Int32
  height : Int32
  margin : Int32
  gutter : Int32
  creep : Int32
} derive(Eq, Debug)

///|
pub(all) struct Rect {
  x : Int32
  y : Int32
  width : Int32
  height : Int32
} derive(Eq, Debug)

///|
pub(all) struct Layout {
  left : Rect
  right : Rect
} derive(Eq, Debug)

///|
/// Reject clipping, overlapping panels and unsafe integer arithmetic.
pub fn layout(paper : Paper, depth : Int32) -> Result[Layout, PlanError] {
  if paper.width < 1 ||
    paper.width > 10000 ||
    paper.height < 1 ||
    paper.height > 10000 ||
    paper.margin < 0 ||
    paper.margin > 10000 ||
    paper.gutter < 0 ||
    paper.gutter > 10000 ||
    paper.creep < 0 ||
    paper.creep > 1000 ||
    depth < 0 ||
    depth > 31 {
    return Err(Geometry)
  }
  let width = (paper.width - 2 * paper.margin - paper.gutter) / 2
  let height = paper.height - 2 * paper.margin
  let shift = depth * paper.creep
  if width <= 0 || height <= 0 || 2 * shift > paper.gutter {
    return Err(Geometry)
  }
  Ok({
    left: { x: paper.margin + shift, y: paper.margin, width, height, },
    right: {
      x: paper.width - paper.margin - width - shift,
      y: paper.margin,
      width,
      height,
    },
  })
}

///|
pub extend Paper with Eq::{equal, not_equal}

///|
pub extend Paper with Debug::{to_repr}

///|
pub extend Rect with Eq::{equal, not_equal}

///|
pub extend Rect with Debug::{to_repr}

///|
pub extend Layout with Eq::{equal, not_equal}

///|
pub extend Layout with Debug::{to_repr}
