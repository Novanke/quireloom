///|
test "stable machine readable report and explicit blanks" {
  let p = impose(3, 4).unwrap()
  assert_eq(
    csv_report(p).unwrap(),
    "signature,depth,face,left,right,rotation\n1,0,front,,1,0\n1,0,back,2,3,0\n",
  )
  assert_eq(
    json_report(p).unwrap(),
    "{\"page_count\":3,\"binding\":\"left\",\"duplex\":\"long-edge\",\"sheets\":[{\"signature\":1,\"depth\":0,\"front\":{\"left\":null,\"right\":1,\"rotation\":0},\"back\":{\"left\":2,\"right\":3,\"rotation\":0}}]}",
  )
  p.sheets.clear()
  assert_true(json_report(p) is Err(_))
  assert_true(csv_report(p) is Err(_))
}
