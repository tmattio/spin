open Cmdliner;
open Spin;

let run = (~generator, ()) => {
  switch (generator) {
  | None =>
    let config = Generators.get_project_config();
    let source = Source.of_string(config.source);
    let generators =
      Generators.list(source)
      |> List.map(~f=Config_file.Generators.parse_doc);

    Console.log(
      <Pastel> "The generators available for this project are:\n" </Pastel>,
    );

    List.iter(
      generators,
      ~f=el => {
        Console.log(
          <Pastel color=Pastel.Blue bold=true> {"    " ++ el.name} </Pastel>,
        );
        Console.log(<Pastel> {"      " ++ el.description ++ "\n"} </Pastel>);
      },
    );

  | Some(generatorName) =>
    let config = Generators.get_project_config();
    let source = Source.of_string(config.source);
    Generators.generate(generatorName, ~source);
  };

  Lwt.return();
};

let cmd = {
  let doc = "Generate a new component in the current project";

  let generator = {
    let doc = "The generator to use to create the new component.";
    Arg.(
      value & pos(0, some(string), None) & info([], ~docv="GENERATOR", ~doc)
    );
  };

  let runCommand = generator =>
    run(~generator) |> Errors.handle_errors |> Lwt_main.run;

  (
    Term.(const(runCommand) $ generator),
    Term.info(
      "gen",
      ~doc,
      ~envs=Man.envs,
      ~version=Man.version,
      ~exits=Man.exits,
      ~man=Man.man,
      ~sdocs=Man.sdocs,
    ),
  );
};
