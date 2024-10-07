let new_cmd ~template ~path =
  let template_source = Spin.resolve_template_source template in
  let template_config = Spin.get_template_config template_source in
  let template_context = Spin.build_template_context template_config in
  let target_dir = match path with
    | Some path -> path
    | None -> Sys.getcwd ()
  in
  Spin.generate_project template_source template_config template_context target_dir;
  0

(* Command line interface *)

open Cmdliner

let template =
  let doc =
    "The template to use. The template can be the name of an official \
     template, a local directory or a remote git repository."
  in
  let docv = "TEMPLATE" in
  Arg.(required & pos 0 (some string) None & info [] ~doc ~docv)

let path =
  let doc =
    "The path where the project will be generated. If absent, the project will \
     be generated in the current working directory."
  in
  let docv = "PATH" in
  Arg.(value & pos 1 (some string) None & info [] ~doc ~docv)

let new_t =
  let open Common.Syntax in
  let+ template = template and+ path = path and+ _term = Common.term in
  new_cmd ~template ~path

let cmd =
  let doc = "Generate a new project from a template" in
  let man =
    [
      `S Manpage.s_description;
      `P "This command generates a new project based on the specified template.";
      `P "The TEMPLATE argument can be:";
      `Noblank;
      `I ("", "- The name of an official template");
      `Noblank;
      `I ("", "- A path to a local directory containing a template");
      `Noblank;
      `I ("", "- A URL to a remote git repository containing a template");
      `P
        "The PATH argument is optional and specifies where the project will be \
         generated.";
      `P
        "If PATH is not provided, the project will be generated in the current \
         working directory.";
      `S Manpage.s_examples;
      `P "Create a new project using an official template:";
      `Pre "  $ spin new cli";
      `P "Create a new project from a local template in a specific directory:";
      `Pre "  $ spin new ./my-custom-template my-project";
      `P "Create a new project from a remote git repository:";
      `Pre "  $ spin new https://github.com/user/repo my-project";
      `P "Create a new project in the current directory:";
      `Pre "  $ spin new web";
    ]
  in
  Cmd.v (Cmd.info "new" ~doc ~man) new_t

(* Exported command *)
let cmd = cmd
