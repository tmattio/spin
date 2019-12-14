open TestFramework;
open Spin;

describe("Test Template", ({test, describe, _}) => {
  test("generate", ({expect, _}) => {
    let dest = TestUtils.get_tempdir("generate");
    let source =
      Utils.Filename.join(["test", "resources", "sample_template"]);
    Template.generate(source, dest, ~useDefaults=true);

    let generatedFiles = Utils.Sys.ls_dir(dest);
    let generatedFile =
      Utils.Filename.join([dest, "dirname", "filename.txt"]);
    let generatedConf = Utils.Filename.join([dest, ".spin"]);

    expect.list([generatedConf, generatedFile]).toEqual(generatedFiles);

    let generatedContent = Stdio.In_channel.read_all(generatedFile);
    expect.equal("Hello World!", generatedContent);
  });

  test("generate configuration", ({expect, _}) => {
    let dest = TestUtils.get_tempdir("generate_config");
    let source =
      Utils.Filename.join(["test", "resources", "sample_template"]);
    Template.generate(source, dest, ~useDefaults=true);

    let generatedConfContent =
      Sexplib.Sexp.load_sexps(Utils.Filename.join([dest, ".spin"]));
    expect.list([
      Sexp.List([
        Sexp.Atom("Source"),
        Sexp.Atom(
          Utils.Filename.join(["test", "resources", "sample_template"]),
        ),
      ]),
      Sexp.List([
        Sexp.Atom("Cfg_str"),
        Sexp.Atom("dirname"),
        Sexp.Atom("dirname"),
      ]),
      Sexp.List([
        Sexp.Atom("Cfg_str"),
        Sexp.Atom("filename"),
        Sexp.Atom("filename"),
      ]),
      Sexp.List([
        Sexp.Atom("Cfg_str"),
        Sexp.Atom("content"),
        Sexp.Atom("Hello World!"),
      ]),
    ]).
      toEqual(
      generatedConfContent,
    );
  });

  test("ignore files", ({expect, _}) => {
    let dest = TestUtils.get_tempdir("ignore_files");
    let source =
      Utils.Filename.join(["test", "resources", "template_with_ignores"]);
    Template.generate(source, dest, ~useDefaults=true);

    let generatedFiles = Utils.Sys.ls_dir(dest);
    let expected = [
      Utils.Filename.concat(dest, ".spin"),
      Utils.Filename.concat(dest, "this_one_matches_but_condition_is_false"),
      Utils.Filename.concat(dest, "f.dont_ignore_me"),
    ];
    expect.list(expected).toEqual(generatedFiles);
  });
});
