open Alcotest;
open Spin;

let test_list_generators = () => {
  let working_dir = Test_utils.get_tempdir("list-generators");
  let template_dir =
    Utils.Filename.join([
      Caml.Sys.getcwd(),
      "test",
      "resources",
      "sample_template",
    ]);

  let status_new =
    Test_utils.exec([|"new", "--default", template_dir, working_dir|]);
  check(int, "same value", status_new, 0);

  let status_gen = Test_utils.exec([|"gen"|], ~dir=working_dir);
  
  check(int, "same value", status_gen, 0);
};

let suite = [
  (
    "List project generators",
    `Quick,
    test_list_generators,
  ),
];