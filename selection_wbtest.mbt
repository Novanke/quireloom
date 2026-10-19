///|
test "selection preserves authored order repeats and intentional blanks" {
  assert_eq(
    parse_selection(" 3-1, b,2, 5-6 ", 6),
    Ok([Page(3), Page(2), Page(1), Blank, Page(2), Page(5), Page(6)]),
  )
  for
    invalid in [
      "", "0", "1,", "1--2", "1 2", "1-b", "7", "10000000000000", "b2",
    ] {
    assert_true(parse_selection(invalid, 6) is Err(_))
  }
  assert_true(parse_selection("1-100000,1", 100000) is Err(_))
  assert_eq(parse_selection("100000-1", 100000).unwrap().length(), 100000)
}
