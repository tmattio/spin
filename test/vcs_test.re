open Alcotest;
open Spin;

/** Test suite for the Vcs module. */

let test_is_git_url = () => {
  let result = Vcs.is_git_url("git@github.com:tmattio/spin-minimal.git");
  check(bool, "same value", result, true);
};

let suite = [
  ("is_git_url returns true when given a git URL", `Quick, test_is_git_url),
];