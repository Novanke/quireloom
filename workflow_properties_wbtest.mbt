///|
test "8192 generalized jobs conserve logical positions across signature strategies" {
  let mut cases = 0
  for count in 1..<=256 {
    let document : Document = {
      pages: Array::makei(count, fn(i) {
        if i % 7 == 0 {
          Empty
        } else {
          Source("book", count - i)
        }
      }),
      sections: [],
    }
    for maximum in [4, 12, 32, 128] {
      for policy in [Fill, Balanced] {
        for binding in [Left, Right] {
          for duplex in [LongEdge, ShortEdge] {
            let booklet = impose_document(
              document,
              plan_gatherings(count, maximum, policy).unwrap(),
              binding,
              duplex,
            ).unwrap()
            let recovered = recover_booklet(booklet).unwrap()
            assert_eq(recovered.length(), (count + 3) / 4 * 4)
            for index in 0..<count {
              assert_eq(recovered[index], document.pages[index])
            }
            let seen = Array::make(count, 0)
            for sheet in booklet.sheets {
              for
                slot in [
                  sheet.front.left,
                  sheet.front.right,
                  sheet.back.left,
                  sheet.back.right,
                ] {
                match slot {
                  Page(n) => seen[n - 1] += 1
                  Blank => ()
                }
              }
            }
            for occurrences in seen {
              assert_eq(occurrences, 1)
            }
            cases += 1
          }
        }
      }
    }
  }
  assert_eq(cases, 8192)
}

///|
test "large jobs and print resource limits remain bounded" {
  let document : Document = {
    pages: Array::makei(100000, fn(i) { Source("book", i + 1) }),
    sections: [],
  }
  let booklet = impose_document(
    document,
    plan_gatherings(100000, 128, Balanced).unwrap(),
    Right,
    ShortEdge,
  ).unwrap()
  let options : PrintOptions = {
    copies: 4,
    reverse_sheets: true,
    collation: Uncollated,
    mode: Manual(Reversed),
  }
  let schedule = schedule_print(booklet, options).unwrap()
  assert_eq(schedule.passes[0].impressions.length(), 100000)
  assert_eq(verify_schedule(booklet, schedule), Ok(()))
  assert_true(schedule_print(booklet, { ..options, copies: 5, }) is Err(_))
  let first = booklet.sheets[0]
  booklet.sheets[0] = { ..first, depth: -1, }
  assert_true(recover_booklet(booklet) is Err(_))
}

///|
test "untrusted section metadata cannot mislabel or omit source provenance" {
  for
    spans in [
      [{ source: "wrong", first: 1, count: 2, }],
      [{ source: "book", first: 2, count: 1, }],
      [{ source: "book", first: 1, count: 1, }],
      [{ source: "book", first: 2147483647, count: 2, }],
    ] {
    assert_true(
      validate_document({
        pages: [Source("book", 1), Source("book", 2)],
        sections: spans,
      })
      is Err(_),
    )
  }
}

///|
test "malformed job fields produce actionable paths instead of silently defaulting" {
  let original = fixture_job()
  for
    text in [
      original.replace(
        old="\"source_pages\":19",
        new="\"source_pages\":2147483648",
      ),
      original.replace(old="\"copies\":2", new="\"copies\":null"),
      original.replace(old="\"maximum\":16", new="\"maximum\":7"),
      original.replace(old="\"width\":297", new="\"width\":1e300"),
    ] {
    let rejected = match parse_job(text) {
      Err(_) => true
      Ok(spec) => build_job(spec) is Err(_)
    }
    assert_true(rejected)
  }
  match parse_job(original.replace(old="\"copies\":2", new="\"copies\":1.5")) {
    Err(e) => assert_eq(e.field, "$.print.copies")
    Ok(_) => fail("fractional copies accepted")
  }
}
