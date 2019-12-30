open Test_framework;
open Spin;

describe("Test Vcs", ({test, describe, _}) => {
  test("is_git_url returns true when given a git URL", ({expect, _}) => {
    let result = Vcs.is_git_url("git@github.com:tmattio/spin-minimal.git");
    expect.bool(result).toBe(true);
  });
  test("git_clone clones the given git repository", ({expect, _}) => {
    /* let tmpdir = get_tempdir("gitClone");
       let destination = Utils.Filename.concat(tmpdir, "spin-templates");
       let result =
         Vcs.gitClone(
           "https://github.com/tmattio/spin-templates.git",
           ~destination,
         );

       let list = Lwt_main.run(result);
       Console.log(list); */
    ()
  });
});
