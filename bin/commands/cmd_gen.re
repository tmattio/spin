open Cmdliner;
open Spin;

let run = (~generator, ()) => {
  switch (generator) {
  | None =>
    let config = Generators.getProjectConfig();
    let source = Source.ofString(config.source);
    let generators =
      Generators.listGenerators(source)
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
    let config = Generators.getProjectConfig();
    let source = Source.ofString(config.source);
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
    run(~generator) |> Errors.handleErrors |> Lwt_main.run;

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
