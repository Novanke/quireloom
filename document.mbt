///|
pub(all) enum ContentPage {
  Source(String, Int32)
  Empty
} derive(Eq, Debug)

///|
pub extend ContentPage with Eq::{equal, not_equal}

///|
pub extend ContentPage with Debug::{to_repr}

///|
pub(all) struct Section {
  source : String
  source_pages : Int32
  selection : String
  start_on_recto : Bool
}

///|
pub(all) struct SectionSpan {
  source : String
  first : Int32
  count : Int32
}

///|
pub(all) struct Document {
  pages : Array[ContentPage]
  sections : Array[SectionSpan]
}

///|
/// Join selected source pages. Odd logical pages are rectos for either binding.
/// Alignment blanks belong to the document and remain distinguishable from padding.
pub fn assemble_document(
  sections : Array[Section],
) -> Result[Document, WorkflowError] {
  if sections.is_empty() || sections.length() > 1000 {
    return Err(workflow_error("sections", "expected 1..1000 sections"))
  }
  let pages : Array[ContentPage] = []
  let spans : Array[SectionSpan] = []
  let source_lengths : Map[String, Int32] = Map([])
  for index, section in sections {
    let field = "sections[\{index}]"
    if section.source.is_blank() || section.source.length() > 128 {
      return Err(
        workflow_error(
          field + ".source",
          "expected a nonblank identifier of at most 128 code units",
        ),
      )
    }
    match source_lengths.get(section.source) {
      Some(previous) if previous != section.source_pages =>
        return Err(
          workflow_error(
            field + ".source_pages",
            "conflicting lengths for the same source",
          ),
        )
      _ => source_lengths.set(section.source, section.source_pages)
    }
    let selected = match
      parse_selection(section.selection, section.source_pages) {
      Err(e) => return Err(workflow_error(field + "." + e.field, e.message))
      Ok(pages) => pages
    }
    let align = section.start_on_recto && pages.length() % 2 == 1
    let extra = if align { 1 } else { 0 }
    if pages.length() + selected.length() + extra > 100000 {
      return Err(
        workflow_error(field, "assembled document exceeds 100000 logical pages"),
      )
    }
    if align {
      pages.push(Empty)
    }
    spans.push({
      source: section.source,
      first: pages.length() + 1,
      count: selected.length(),
    })
    for page in selected {
      pages.push(
        match page {
          Page(n) => Source(section.source, n)
          Blank => Empty
        },
      )
    }
  }
  Ok({ pages, sections: spans, })
}

///|
/// Validate externally constructed documents before using their page map.
pub fn validate_document(document : Document) -> Result[Unit, WorkflowError] {
  if document.pages.is_empty() || document.pages.length() > 100000 {
    return Err(workflow_error("document.pages", "expected 1..100000 pages"))
  }
  for index, page in document.pages {
    match page {
      Source(source, number) =>
        if source.is_blank() ||
          source.length() > 128 ||
          number < 1 ||
          number > 100000 {
          return Err(
            workflow_error(
              "document.pages[\{index}]",
              "invalid source reference",
            ),
          )
        }
      Empty => ()
    }
  }
  let mut previous_end = 0
  for index, span in document.sections {
    if span.first <= previous_end ||
      span.count < 1 ||
      span.count > document.pages.length() ||
      span.first > document.pages.length() - span.count + 1 {
      return Err(
        workflow_error(
          "document.sections[\{index}]",
          "overlapping or out-of-range span",
        ),
      )
    }
    previous_end = span.first + span.count - 1
  }
  Ok(())
}
