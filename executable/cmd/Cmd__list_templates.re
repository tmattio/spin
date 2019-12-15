open Cmdliner;
open Spin;

let run = () => {
  TemplateOfficial.ensureDownloaded();
  let templates = TemplateOfficial.all();

  Console.log(<Pastel> "The official templates are:\n" </Pastel>);

  List.iter(
    templates,
    ~f=el => {
      Console.log(
        <Pastel color=Pastel.Blue bold=true> {"    " ++ el.name} </Pastel>,
      );
      Console.log(<Pastel> {"      " ++ el.description ++ "\n"} </Pastel>);
    },
  );

  Lwt.return();
};

let cmd = {
  let doc = "List the official spin templates";
  let runCommand = () => run |> Errors.handleErrors |> Lwt_main.run;

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
