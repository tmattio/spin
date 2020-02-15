open Alcotest;
open Spin;

let test_postinstall_command_fail = () => {
  let working_dir = Test_utils.get_tempdir("template-postinstall-208");
  let template_dir =
    Utils.Filename.join([
      Caml.Sys.getcwd(),
      "test",
      "resources",
      "sample_template_postinstall_error",
    ]);

  let status_new =
    Test_utils.exec([|"new", "--default", template_dir, working_dir|]);
  
  check(int, "same value", status_new, 210);
};

let test_postinstall_command_unavailable = () => {
  let working_dir = Test_utils.get_tempdir("template-postinstall-211");
  let template_dir =
    Utils.Filename.join([
      Caml.Sys.getcwd(),
      "test",
      "resources",
      "sample_template_postinstall_unavailable",
    ]);

  let status_new =
    Test_utils.exec([|"new", "--default", template_dir, working_dir|]);

  check(int, "same value", status_new, 211);
};

let suite = [
  (
    "Postinstall command failing exits gracefully",
    `Quick,
    test_postinstall_command_fail,
  ),
  (
    "Postinstall command not being available exits gracefully",
    `Quick,
    test_postinstall_command_unavailable,
  ),
];