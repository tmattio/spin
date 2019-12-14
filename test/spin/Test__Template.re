open TestFramework;
open Spin;

describe("Test Template", ({test, describe, _}) => {
  test("generate", ({expect, _}) => {
    let dest = TestUtils.get_tempdir("generate");
    let source =
      Utils.Filename.join(["test", "resources", "sample_template"]);
    Template.generate(source, dest, ~useDefaults=true);

    let generatedFiles = Utils.Sys.ls_dir(dest);
    let destFullPath = Utils.Filename.join([dest, "dirname", "filename.txt"]);
    expect.equal([destFullPath], generatedFiles);

    let generatedContent = Stdio.In_channel.read_all(destFullPath);
    expect.equal("Hello World!", generatedContent);
  });

  test("ignore files", ({expect, _}) => {
    let dest = TestUtils.get_tempdir("ignore_files");
    let source =
      Utils.Filename.join(["test", "resources", "template_with_ignores"]);
    Template.generate(source, dest, ~useDefaults=true);

    let generatedFiles = Utils.Sys.ls_dir(dest);
    let expected = [
      Utils.Filename.concat(dest, "this_one_matches_but_condition_is_false"),
      Utils.Filename.concat(dest, "f.dont_ignore_me"),
    ];
    expect.equal(expected, generatedFiles);
  });
});
