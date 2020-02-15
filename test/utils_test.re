open Alcotest;
open Spin;

/** Test suite for the Utils module. */

let test_join_string = () => {
  let result = Utils.String.join(["1", "2"], ~sep=", ");
  check(string, "same string", result, "1, 2");
};

let test_ls_dir = () => {
  let root_dir =
    Utils.Filename.join(["test", "resources", "sample_hierarchy"]);

  let files =
    Utils.Sys.ls_dir(root_dir) |> List.sort(~compare=String.compare);

  let expected =
    [
      Utils.Filename.join([root_dir, "d1", "f1"]),
      Utils.Filename.join([root_dir, "d2", "f2"]),
    ]
    |> List.sort(~compare=String.compare);

  check(list(string), "same value", files, expected);
};

let suite = [
  ("can join a list of string", `Quick, test_join_string),
  (
    "ls_dir returns the correct list of files in the directory",
    `Quick,
    test_ls_dir,
  ),
];