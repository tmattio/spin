open Spin;
open Test_framework;

describe("Integration test generators", ({test, _}) => {
  test("List generators", ({expect}) => {
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
    expect.int(status_new).toBe(0);

    let status_gen = Test_utils.exec([|"gen"|], ~dir=working_dir);
    expect.int(status_gen).toBe(0);
  })
});
