///|
pub(all) enum Binding {
  Left
  Right
} derive(Eq, Debug)

///|
pub(all) enum Duplex {
  LongEdge
  ShortEdge
} derive(Eq, Debug)

///|
pub(all) enum Slot {
  Page(Int32)
  Blank
} derive(Eq, Debug)

///|
pub(all) struct Signature {
  index : Int32
  start : Int32
  pages : Int32
  real_pages : Int32
} derive(Eq, Debug)

///|
pub(all) struct Face {
  left : Slot
  right : Slot
  rotation : Int32
} derive(Eq, Debug)

///|
pub(all) struct Sheet {
  signature : Int32
  depth : Int32
  front : Face
  back : Face
} derive(Eq, Debug)

///|
pub(all) struct Plan {
  page_count : Int32
  signature_pages : Int32
  binding : Binding
  duplex : Duplex
  sheets : Array[Sheet]
} derive(Eq, Debug)

///|
pub(all) enum PlanError {
  PageCount
  SignatureSize
  Geometry
  CorruptPlan(String)
} derive(Eq, Debug)

///|
/// Bounded inputs keep page arithmetic exact on every backend.
pub fn validate_config(
  pages : Int32,
  signature_pages : Int32,
) -> Result[Unit, PlanError] {
  if pages < 1 || pages > 100000 {
    return Err(PageCount)
  }
  if signature_pages < 4 || signature_pages > 128 || signature_pages % 4 != 0 {
    return Err(SignatureSize)
  }
  Ok(())
}

///|
pub extend Binding with Eq::{equal, not_equal}

///|
pub extend Binding with Debug::{to_repr}

///|
pub extend Duplex with Eq::{equal, not_equal}

///|
pub extend Duplex with Debug::{to_repr}

///|
pub extend Slot with Eq::{equal, not_equal}

///|
pub extend Slot with Debug::{to_repr}

///|
pub extend Signature with Eq::{equal, not_equal}

///|
pub extend Signature with Debug::{to_repr}

///|
pub extend Face with Eq::{equal, not_equal}

///|
pub extend Face with Debug::{to_repr}

///|
pub extend Sheet with Eq::{equal, not_equal}

///|
pub extend Sheet with Debug::{to_repr}

///|
pub extend Plan with Eq::{equal, not_equal}

///|
pub extend Plan with Debug::{to_repr}

///|
pub extend PlanError with Eq::{equal, not_equal}

///|
pub extend PlanError with Debug::{to_repr}
