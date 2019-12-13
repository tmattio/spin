open TestFramework;
open Spin;

describe("Test Utils", ({test, describe, _}) => {
  test("join string", ({expect, _}) => {
    let joinedString = Utils.String.join(["1", "2"], ~sep=", ");
    expect.equal(joinedString, "1, 2");
  });

  test("list directory", ({expect, _}) => {
    let rootDir =
      Utils.Filename.join(["test", "resources", "sample_hierarchy"]);
    let files = Utils.Sys.ls_dir(rootDir);
    expect.equal(
      files,
      [
        Utils.Filename.join([rootDir, "d1", "f1"]),
        Utils.Filename.join([rootDir, "d2", "f2"]),
      ],
    );
  });
});
