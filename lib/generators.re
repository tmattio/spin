let get_project_root = () => {
  let root =
    Config_file.Project.path
    |> Utils.Sys.get_parent_file
    |> Option.map(~f=Caml.Filename.dirname);

  switch (root) {
  | Some(f) => f
  | None => raise(Errors.Current_directory_not_a_spin_project)
  };
};

let get_project_config = () => {
  get_project_root() |> Config_file.Project.parse;
};

let get_project_doc = () => {
  get_project_root() |> Config_file.Project.parse_doc;
};

let list = (source: Source.t) => {
  let local_path = Source.to_local_path(source);
  let generators_dir = Utils.Filename.concat(local_path, "generators");

  if (Utils.Filename.test(Utils.Filename.Exists, generators_dir)) {
    Utils.Sys.ls_dir(~recursive=false, generators_dir)
    |> List.filter(~f=el => {
         Utils.Filename.test(
           Utils.Filename.Exists,
           Utils.Filename.concat(el, "spin"),
         )
       });
  } else {
    [];
  };
};

let get_generator = (name, ~source: Source.t) => {
  let generators = list(source);
  switch (
    List.find(
      generators,
      ~f=el => {
        let doc = Config_file.Generators.parse_doc(el);
        String.equal(doc.name, name);
      },
    )
  ) {
  | Some(v) => v
  | None => raise(Errors.Generator_does_not_exist(name))
  };
};

let ensure_files_dont_exist = files => {
  let existing_file =
    List.find(files, ~f=el => Utils.Filename.test(Utils.Filename.Exists, el));

  switch (existing_file) {
  | Some(v) => raise(Errors.Generator_files_already_exist(v))
  | None => ()
  };
};

let generate_file = (~destination: string, ~models, source) => {
  let source = Jg_wrapper.from_string(source, ~models);
  let destination = Jg_wrapper.from_string(destination, ~models);

  let data =
    Stdio.In_channel.read_all(source) |> Jg_wrapper.from_string(~models);

  let parent_dir = Utils.Filename.dirname(destination);
  Utils.Filename.mkdir(parent_dir, ~parent=true);
  Stdio.Out_channel.write_all(destination, ~data);
};

let generate = (~use_defaults=false, ~source: Source.t, name) => {
  let generator_path = get_generator(name, ~source);
  let project_root = get_project_root();
  let project_config = get_project_config();
  let generator =
    Config_file.Generators.parse(
      generator_path,
      ~use_defaults,
      ~models=project_config.models,
    );

  let rec loop =
    fun
    | [] => ()
    | [(f: Config_file_generators.file), ...fs] => {
        generate_file(
          Utils.Filename.concat(generator_path, f.source),
          ~destination=Utils.Filename.concat(project_root, f.destination),
          ~models=generator.models,
        );
        loop(fs);
      };

  generator.files
  |> List.map(~f=(el: Config_file_generators.file) =>
       Utils.Filename.concat(project_root, el.destination)
     )
  |> ensure_files_dont_exist;

  Pastel.make([
    "\n🏗️  Creating a new ",
    Pastel.make(~color=Pastel.Blue, ~bold=true, [generator.name]),
  ])
  |> Stdio.print_endline;

  loop(generator.files);

  Pastel.make(~color=Pastel.GreenBright, ~bold=true, ["Done!\n"])
  |> Stdio.print_endline;

  switch (generator.message) {
  | Some(message) =>
    Pastel.make(~color=Pastel.Yellow, ~bold=true, [message, "\n"])
    |> Stdio.print_endline
  | None => ()
  };
};
