open Cmdliner;

let defaultCmd = {
  let doc = "Scaffold new ReasonML/OCaml projects.";
  (
    Term.(ret(const(_ => `Help((`Pager, None))) $ const())),
    Term.info(
      "spin",
      ~doc,
      ~envs=Man.envs,
      ~version=Man.version,
      ~exits=Man.exits,
      ~man=Man.man,
      ~sdocs=Man.sdocs,
    ),
  );
};

let argv =
  Sys.get_argv()
  |> Array.map(~f=arg =>
       switch (arg) {
       | "-v" => "--version"
       | x => x
       }
     );

let _ = Term.eval_choice(defaultCmd, Cmd.all, ~argv) |> Term.exit;
