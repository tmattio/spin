open Alcotest;
open Spin;

/** Test suite for the Vcs module. */

let test_generate_template = () => {
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
    [expected_content_filepath, expected_conf_filepath]
    |> List.sort(~compare=String.compare);

  check(list(string), "same value", expected, generated_files);

  let generated_content =
    Stdio.In_channel.read_all(expected_content_filepath);

  check(string, "same value", "Hello World!", generated_content);
};
let test_generate_configuration = () => {
  let dest = Test_utils.get_tempdir("generate_configuration");
  let source =
    Source.Local_dir(
      Utils.Filename.join(["test", "resources", "sample_template"]),
    );

  Template.generate(source, dest, ~use_defaults=true);

  let generated = Stdio.In_channel.read_all(Utils.Filename.join([dest, ".spin"]));

  let expected = "";

  check(string, "same string", expected, generated);
};
let test_ignore_files = () => {
  let dest = Test_utils.get_tempdir("ignore_files");
  let source =
    Source.Local_dir(
      Utils.Filename.join(["test", "resources", "template_with_ignores"]),
    );
  Template.generate(source, dest, ~use_defaults=true);

  let generated_files =
    Utils.Sys.ls_dir(dest) |> List.sort(~compare=String.compare);

  let expected =
    [
      Utils.Filename.concat(dest, ".spin"),
      Utils.Filename.concat(dest, "this_one_matches_but_condition_is_false"),
      Utils.Filename.concat(dest, "f.dont_ignore_me"),
    ]
    |> List.sort(~compare=String.compare);

  check(list(string), "same list", expected, generated_files);
};

let suite = [
  (
    "can generate a new template from a directory",
    `Quick,
    test_generate_template,
  ),
  (
    "generating a template also generates a configuration file",
    `Quick,
    test_generate_configuration,
  ),
  (
    "generating a template does not generate ignore files",
    `Quick,
    test_ignore_files,
  )
];