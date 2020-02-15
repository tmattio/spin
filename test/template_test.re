open Test_framework;
open Spin;

describe("Test Template", ({test, describe, _}) => {
  test("generate", ({expect, _}) => {
    let dest = Test_utils.get_tempdir("generate");
    let source =
      Source.Local_dir(
        Utils.Filename.join(["test", "resources", "sample_template"]),
      );
    Template.generate(source, dest, ~use_defaults=true);

    let generated_files =
      Utils.Sys.ls_dir(dest) |> List.sort(~compare=String.compare);
    let expected_content_filepath =
      Utils.Filename.join([dest, "dirname", "filename.txt"]);
    let expected_conf_filepath = Utils.Filename.join([dest, ".spin"]);

    let expected =
      expect.list(
        [expected_content_filepath, expected_conf_filepath]
        |> List.sort(~compare=String.compare),
      );

    expected.toEqual(generated_files);

    let generated_content =
      Stdio.In_channel.read_all(expected_content_filepath);
    let expected = expect.string("Hello World!");
    expected.toEqual(generated_content);
  });

  test("generate configuration", ({expect, _}) => {
    let dest = Test_utils.get_tempdir("generate_configuration");
    let source =
      Source.Local_dir(
        Utils.Filename.join(["test", "resources", "sample_template"]),
      );

    Template.generate(source, dest, ~use_defaults=true);

    let generatedConfContent =
      Sexplib.Sexp.load_sexps(Utils.Filename.join([dest, ".spin"]));

    let expected =
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
      ]);

    expected.toEqual(generatedConfContent);
  });

  test("ignore files", ({expect, _}) => {
    let dest = Test_utils.get_tempdir("ignore_files");
    let source =
      Source.Local_dir(
        Utils.Filename.join(["test", "resources", "template_with_ignores"]),
      );
    Template.generate(source, dest, ~use_defaults=true);

    let generated_files =
      Utils.Sys.ls_dir(dest) |> List.sort(~compare=String.compare);
    let expected =
      expect.list(
        [
          Utils.Filename.concat(dest, ".spin"),
          Utils.Filename.concat(
            dest,
            "this_one_matches_but_condition_is_false",
          ),
          Utils.Filename.concat(dest, "f.dont_ignore_me"),
        ]
        |> List.sort(~compare=String.compare),
      );
    expected.toEqual(generated_files);
  });
});
