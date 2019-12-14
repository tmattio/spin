open Jingoo;

type templateOrigin =
  | Name(string)
  | Git(string)
  | LocalDir(string);

let originToLocalPath =
  fun
  | Name(s) => Utils.Filename.concat(TemplateOfficial.path, s)
  | LocalDir(s) => s
  | Git(s) => {
      let tempdir = Utils.Sys.get_tempdir("spin-template");
      let _ = Vcs.gitClone(s, ~destination=tempdir);
      tempdir;
    };

let exists = (template: string): bool => {
  let spinFile = Utils.Filename.concat(template, "template");
  let spinFile = Utils.Filename.concat(spinFile, "spin");
  Utils.Filename.test(Utils.Filename.Exists, spinFile);
};

let ensureEmptyDir = (d: string) =>
  if (Utils.Filename.test(Utils.Filename.Exists, d)) {
    if (Utils.Filename.test(Utils.Filename.Is_file, d)) {
      raise(
        Errors.IncorrectDestinationPath("This path is not a directory."),
      );
    } else if (!List.is_empty(Utils.Sys.ls_dir(d, ~recursive=false))) {
      raise(Errors.IncorrectDestinationPath("This directory is not empty."));
    };
  };

let parseTemplateOrigin = (s: string) =>
  if (exists(s)) {
    LocalDir(s);
  } else if (Vcs.isGitUrl(s)) {
    Git(s);
  } else if (TemplateOfficial.isOfficialTemplate(s)) {
    Name(s);
  } else {
    raise(Errors.IncorrectTemplateName(s));
  };

let createSpinConfig = (~models, destination: string) => {
  let destination = Utils.Filename.concat(destination, ".spin");
  let sexp = Jg_wrapper.to_sexp(models);
  let sexpString = Sexp.to_string(sexp);
  Stdio.Out_channel.write_all(destination, ~data=sexpString);
};

let generateFile =
    (
      ~sourceDirectory: string,
      ~destinationDirectory: string,
      ~models,
      sourceFile,
    ) => {
  let data =
    Stdio.In_channel.read_all(sourceFile) |> Jg_wrapper.from_string(~models);

  let dest =
    sourceFile
    |> Jg_wrapper.from_string(~models)
    |> String.substr_replace_first(
         ~pattern=sourceDirectory,
         ~with_=destinationDirectory,
       );

  let parent_dir = Utils.Filename.dirname(dest);
  Utils.Filename.mkdir(parent_dir, ~parent=true);
  Utils.Filename.cp([sourceFile], dest);
  Stdio.Out_channel.write_all(dest, ~data);
};

let generate = (~useDefaults=false, template: string, destination: string) => {
  let () = ensureEmptyDir(destination);

  let origin = template |> parseTemplateOrigin |> originToLocalPath;
  let templatePath = Utils.Filename.concat(origin, "template");

  let templateConfig = ConfigFile.Template.parse(origin, ~useDefaults);
  let models = templateConfig.models;
  let docConfig = ConfigFile.Doc.parse(origin, ~models, ~useDefaults);

  let rec loop =
    fun
    | [] => ()
    | [f, ...fs] => {
        generateFile(
          f,
          ~sourceDirectory=templatePath,
          ~destinationDirectory=destination,
          ~models,
        );
        loop(fs);
      };

  Console.log(
    <Pastel>
      <Pastel> "\n🏗️  Creating a new " </Pastel>
      <Pastel color=Pastel.Blue bold=true> {docConfig.name} </Pastel>
      <Pastel> {" in " ++ destination} </Pastel>
    </Pastel>,
  );
  let templatePathRegex = templatePath;
  let ignoreFiles =
    List.map(templateConfig.ignoreFiles, ~f=file => {
      Utils.Filename.concat(templatePathRegex, file)
    });
  Utils.Sys.ls_dir(templatePath, ~ignore_files=ignoreFiles) |> loop;
  Console.log(
    <Pastel color=Pastel.GreenBright bold=true> "Done!\n" </Pastel>,
  );

  switch (templateConfig.postInstalls) {
  | [] => ()
  | postInstalls =>
    List.iter(
      postInstalls,
      el => {
        switch (el.description) {
        | Some(description) => Console.log(<Pastel> description </Pastel>)
        | None => ()
        };

        let _ =
          Utils.Sys.exec_in_dir(
            el.command,
            ~args=el.args |> Array.of_list,
            ~dir=destination,
          )
          |> Lwt_main.run;

        switch (el.description) {
        | Some(description) =>
          Console.log(
            <Pastel color=Pastel.GreenBright bold=true> "Done!\n" </Pastel>,
          )
        | None => ()
        };
      },
    )
  };

  Console.log(
    <Pastel>
      <Pastel> "🎉  Success! Created the project at " </Pastel>
      <Pastel> destination </Pastel>
    </Pastel>,
  );

  switch (docConfig.commands) {
  | [] => ()
  | commands =>
    Console.log(
      <Pastel>
        "Here are some example commands that you can run inside this directory:"
      </Pastel>,
    );
    List.iter(
      commands,
      ~f=el => {
        Console.log(
          <Pastel color=Pastel.Blue bold=true>
            {"\n    " ++ Jg_wrapper.from_string(el.name, ~models)}
          </Pastel>,
        );
        Console.log(
          <Pastel>
            {"      " ++ Jg_wrapper.from_string(el.description, ~models)}
          </Pastel>,
        );
      },
    );
  };

  Console.log(<Pastel> "\nHappy hacking!" </Pastel>);

  /* Remove spin configuration file from the generated project */
  Utils.Filename.rm([Utils.Filename.concat(destination, "spin")]);
  createSpinConfig(destination, ~models);
};
