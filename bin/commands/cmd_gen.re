open Cmdliner;
open Spin;

let run = (~generator, ()) => {
  Template_official.update();

  switch (generator) {
  | None =>
    let config = Generators.get_project_config();
    let source = Source.of_string(config.source);
    let generators =
      Generators.list(source)
      |> List.map(~f=Config_file.Generators.parse_doc);

    switch (generators) {
    | [] =>
      Console.log(
        <Pastel> "There are no generator for this project." </Pastel>,
      )
    | _ =>
      Console.log(
        <Pastel> "The generators available for this project are:\n" </Pastel>,
      );

      List.iter(
        generators,
        ~f=el => {
          Console.log(
            <Pastel color=Pastel.Blue bold=true> {"    " ++ el.name} </Pastel>,
          );
          Console.log(
            <Pastel> {"      " ++ el.description ++ "\n"} </Pastel>,
          );
        },
      );
    };

  | Some(generator_name) =>
    let config = Generators.get_project_config();
    let source = Source.of_string(config.source);
    Generators.generate(generator_name, ~source);
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

  let run_command = generator =>
    run(~generator) |> Errors.handle_errors |> Lwt_main.run;

  Term.(
    const(run_command) $ generator,
    info(
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