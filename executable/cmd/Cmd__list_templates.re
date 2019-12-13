open Cmdliner;
open Spin;

let run = () => {
  let templates =
    {
      () => {
        TemplateOfficial.ensureDownloaded();
        TemplateOfficial.list();
      };
    }
    |> Errors.handleErrors;

  Console.log(<Pastel> "The official spin templates are:\n" </Pastel>);
  List.iter(templates, ~f=el => Console.log(<Pastel> {"- " ++ el} </Pastel>));

  Lwt.return();
};

let cmd = {
  let doc = "List the official spin templates";
  let runCommand = () => Lwt_main.run(run());

  (
    Term.(app(const(runCommand), const())),
    Term.info(
      "ls",
      ~doc,
      ~envs=Man.envs,
      ~version=Man.version,
      ~exits=Man.exits,
      ~man=Man.man,
      ~sdocs=Man.sdocs,
    ),
  );
};
