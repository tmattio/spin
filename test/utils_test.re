open Test_framework;
open Spin;

describe("Test Utils", ({test, describe, _}) => {
  test("join string", ({expect, _}) => {
    let joined_string = Utils.String.join(["1", "2"], ~sep=", ");
    expect.equal(joined_string, "1, 2");
  });

  test(
    "ls_dir returns the correct list of files in the directory",
    ({expect, _}) => {
    let root_dir =
      Utils.Filename.join(["test", "resources", "sample_hierarchy"]);

    let files =
      Utils.Sys.ls_dir(root_dir) |> List.sort(~compare=String.compare);

    let expected =
      expect.list(
        [
          Utils.Filename.join([root_dir, "d1", "f1"]),
          Utils.Filename.join([root_dir, "d2", "f2"]),
        ]
        |> List.sort(~compare=String.compare),
      );

    expected.toEqual(files);
  });
});
