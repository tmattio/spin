open TestFramework;
open Spin;

describe("Test Vcs", ({test, describe, _}) => {
  describe("listDirRecursively", ({test, _}) => {
    test("gitClone", ({expect, _}) => {
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
    })
  })
});
