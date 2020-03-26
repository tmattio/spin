open Jingoo;

let check_config_file = (c: option(Global_context.t)) =>
  if (Option.is_none(c)) {
    Pastel.make([
      "\n⚠️  No config file found. To save some time in the future, ",
      "create one with ",
      Pastel.make(~color=Pastel.BlueBright, ~bold=true, ["spin config"]),
      ".\n",
    ])
    |> Stdio.print_endline;
  };

let ensure_dir_is_empty = (d: string) =>
  if (Utils.Filename.test(Utils.Filename.Exists, d)) {
    if (Utils.Filename.test(Utils.Filename.Is_file, d)) {
      raise(
        Errors.Incorrect_destination_path("This path is not a directory."),
      );
    } else if (!List.is_empty(Utils.Sys.ls_dir(d, ~recursive=false))) {
      raise(
        Errors.Incorrect_destination_path("This directory is not empty."),
      );
    };
  };

let get_user_config = () => {
  let filepath = Config.SPIN_CONFIG_DIR.get();
  if (Utils.Filename.test(Utils.Filename.Exists, filepath)) {
    Some(Config_file.User.parse(filepath));
  } else {
    None;
  };
};

let generate_file =
    (
      ~source_directory: string,
      ~destination_directory: string,
      ~models,
      source_file,
    ) => {
  let content = Stdio.In_channel.read_all(source_file);

  let data =
    try(Jg_wrapper.from_string(content, ~models)) {
    | _ => raise(Errors.Cannot_parse_template_file(source_file))
    };

  let dest =
    source_file
    |> Jg_wrapper.from_string(~models)
    |> String.substr_replace_first(
         ~pattern=source_directory,
         ~with_=destination_directory,
       );

  let parent_dir = Utils.Filename.dirname(dest);
  Utils.Filename.mkdir(parent_dir, ~parent=true);
  Utils.Filename.cp([source_file], dest);
  Stdio.Out_channel.write_all(dest, ~data);
};

let generate =
    (
      ~use_defaults=false,
      ~global_context=None,
      source: Source.t,
      destination: string,
    ) => {
  check_config_file(global_context);
  ensure_dir_is_empty(destination);

  let origin = Source.to_local_path(source);
  let template_path = Utils.Filename.concat(origin, "template");
  let template_config =
    Config_file.Template.parse(origin, ~use_defaults, ~global_context);
  let models = template_config.models;
  let doc_config = Config_file.Doc.parse(origin, ~models, ~use_defaults);

  let rec loop =
    fun
    | [] => ()
    | [f, ...fs] => {
        generate_file(
          f,
          ~source_directory=template_path,
          ~destination_directory=destination,
          ~models,
        );
        loop(fs);
      };

  Pastel.make([
    "\n🏗️  Creating a new ",
    Pastel.make(~color=Pastel.Blue, ~bold=true, [doc_config.name]),
    " in " ++ destination,
  ])
  |> Stdio.print_endline;

  let template_path_regex = template_path;
  let ignore_files =
    List.map(template_config.ignore_files, ~f=file => {
      Utils.Filename.concat(template_path_regex, file)
    });
  Utils.Sys.ls_dir(template_path, ~ignore_files) |> loop;

  Pastel.make(~color=Pastel.GreenBright, ~bold=true, ["Done!\n"])
  |> Stdio.print_endline;

  switch (template_config.post_installs) {
  | [] => ()
  | post_installs =>
    List.iter(
      post_installs,
      el => {
        switch (el.description) {
        | Some(description) => Stdio.print_endline(description)
        | None => ()
        };

        let dir =
          Option.map(el.working_dir, working_dir =>
            Utils.Filename.concat(destination, working_dir)
          )
          |> Option.value(~default=destination);

        let command_string =
          Utils.String.join([el.command, ...el.args], ~sep=" ");

        switch (
          Utils.Sys.exec("which", ~args=[|el.command|]) |> Lwt_main.run
        ) {
        | WEXITED(0) =>
          let status_code =
            Utils.Sys.exec_in_dir(
              el.command,
              ~args=el.args |> Array.of_list,
              ~dir,
              ~stdout=`Dev_null,
            )
            |> Lwt_main.run;

          switch (status_code) {
          | WEXITED(0) => ()
          | WEXITED(s)
          | WSIGNALED(s)
          | WSTOPPED(s) =>
            raise(Errors.Subprocess_exited_with_non_zero(command_string, s))
          };

          switch (el.description) {
          | Some(description) =>
            Pastel.make(~color=Pastel.GreenBright, ~bold=true, ["Done!\n"])
            |> Stdio.print_endline
          | None => ()
          };
        | _ =>
          Pastel.make(
            ~color=Pastel.Yellow,
            ~bold=true,
            [
              "\nCouldn't find ",
              el.command,
              ".\n",
              "Please run: \"",
              command_string,
              "\"\n",
            ],
          )
          |> Stdio.print_endline
        };
      },
    )
  };

  Stdio.print_endline(
    "🎉  Success! Created the project at " ++ destination,
  );

  switch (template_config.example_commands) {
  | [] => ()
  | commands =>
    Stdio.print_endline(
      "\nHere are some example commands that you can run inside this directory:",
    );
    List.iter(
      commands,
      ~f=el => {
        Pastel.make(
          ~color=Pastel.Blue,
          ~bold=true,
          ["\n    ", Jg_wrapper.from_string(el.name, ~models)],
        )
        |> Stdio.print_endline;

        Stdio.print_endline(
          "      " ++ Jg_wrapper.from_string(el.description, ~models),
        );
      },
    );
  };

  Stdio.print_endline("\nHappy hacking!");

  /* Remove spin configuration file from the generated project */
  Utils.Filename.rm([Utils.Filename.concat(destination, "spin")]);
  Config_file_project.save(
    {models, source: Source.to_string(source)},
    ~from_dir=destination,
  );
};
