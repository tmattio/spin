open Test_framework;
open Spin;

describe("Test Vcs", ({test, describe, _}) => {
  test("is_git_url returns true when given a git URL", ({expect, _}) => {
    let result = Vcs.is_git_url("git@github.com:tmattio/spin-minimal.git");
    expect.bool(result).toBe(true);
  })
});
