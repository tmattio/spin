open Cmdliner;
open Spin;

let run =
    (
      ~template: string,
      ~path: option(string),
      ~use_defaults,
      ~ignore_config,
      (),
    ) => {
  Template_official.update_if_present();

  let path = Option.value(path, ~default=".");
  let source = Source.of_string(template);
  let global_context = ignore_config ? None : Config.read_global_context();

  Template.generate(source, path, ~use_defaults, ~global_context);

  Lwt.return();
};

let cmd = {
  let doc = "Create a new ReasonML/Ocaml project from a template";

  let template = {
    let doc = "The template to use to generate the project. Can be the name of an official template or a git repository.";
    Arg.(
      required
      & pos(0, some(string), None)
      & info([], ~docv="TEMPLATE", ~doc)
    );
  };

  let path = {
    let doc = "The path of the generated project.\nLeave empty to put files into current directory by default.";
    Arg.(value & pos(1, some(string), None) & info([], ~docv="PATH", ~doc));
  };

  let use_defaults = {
    let doc = "Use default values for the configuration.\nThe user will be prompted only for configuration that don't have a default value";
    Arg.(value & flag & info(["default"], ~doc));
  };

  let ignore_config = {
    let doc = "Ignore the user configuration.\nThe user will be prompted for configurations even if they are present in their Spin configuration file.";
    Arg.(value & flag & info(["ignore-config"], ~doc));
  };

  let run_command = (template, path, use_defaults, ignore_config) =>
    run(~template, ~path, ~use_defaults, ~ignore_config)
    |> Errors.handle_errors
    |> Lwt_main.run;

  Term.(
    const(run_command) $ template $ path $ use_defaults $ ignore_config,
    info(
      "new",
      ~doc,
      ~envs=Man.envs,
      ~version=Man.version,
      ~exits=Man.exits,
      ~man=Man.man,
      ~sdocs=Man.sdocs,
    ),
  );
};
