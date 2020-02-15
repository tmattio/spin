open Alcotest;

let test_get_cli_version = () => {
  let version = Test_utils.run([|"--version"|]);
  check(string, "same string", "%%VERSION%%", version)
};

let suite = [
  ("calling cli with --version returns the version", `Quick, test_get_cli_version),
];