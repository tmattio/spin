open Cmdliner;
open Spin;

let run = (~generator) => {
  switch (generator) {
  | None =>
    let config = Generators.getProjectConfig();
    let source = Source.ofString(config.source);
    let generators = Generators.listGenerators(source);

    Console.log(
      <Pastel> "The generators available for this project are:" </Pastel>,
    );

    List.iter(generators, ~f=el =>
      Console.log(<Pastel> {"- " ++ el.name} </Pastel>)
    );

  | Some(generator) =>
    Console.log(
      <Pastel> {"Generating a new moduel with " ++ generator} </Pastel>,
    )
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

  let runCommand = generator => Lwt_main.run(run(~generator));

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
