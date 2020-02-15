open Spin;
open Test_framework;

describe("Integration test templates", ({test, _}) => {
  test("Postinstall command failing exits gracefully", ({expect}) => {
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
    expect.int(status_new).toBe(210);
  })
});

describe("Integration test templates", ({test, _}) => {
  test(
    "Postinstall command not being available exits gracefully", ({expect}) => {
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
    expect.int(status_new).toBe(211);
  })
});
