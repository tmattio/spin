open TestFramework;
open Spin;

describe("Test Template", ({test, describe, _}) => {
  test("generate", ({expect, _}) => {
    let dest = TestUtils.get_tempdir("generateTemplate");
    let source =
      Utils.Filename.join(["test", "resources", "sample_template"]);
    Template.generate(source, dest, ~useDefaults=true);

    let generatedFiles = Utils.Sys.ls_dir(dest);
    let destFullPath = Utils.Filename.join([dest, "dirname", "filename.txt"]);
    expect.equal([destFullPath], generatedFiles);

    let generatedContent = Stdio.In_channel.read_all(destFullPath);
    expect.equal("Hello World!", generatedContent);
  })
});
