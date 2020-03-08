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

    switch (generators) {
    | [] => Stdio.print_endline("There are no generator for this project.")
    | _ =>
      Stdio.print_endline("The generators available for this project are:\n");

      List.iter(generators, ~f=el => {
        ["    " ++ el.name]
        |> Pastel.make(~color=Pastel.Blue, ~bold=true)
        |> Stdio.print_endline
      });
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
