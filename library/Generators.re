let getProjectConfig = () => {
  let rec loop = el => {
    switch (el) {
    | "/"
    | "." => raise(Errors.CurrentDirectoryNotASpinProject)
    | dirname =>
      let f = ConfigFile.Project.path(dirname);
      if (Utils.Filename.test(Utils.Filename.Exists, f)) {
        ConfigFile.Project.parse(dirname);
      } else {
        loop(Caml.Filename.dirname(el));
      };
    };
  };

  loop(Caml.Sys.getcwd());
};

let listGenerators = (source: Source.t): list(ConfigFile.Generators.t) => {
  let localPath = Source.toLocalPath(source);
  let generatorsDir = Utils.Filename.concat(localPath, "generators");

  Utils.Sys.ls_dir(~recursive=false, generatorsDir)
  |> List.filter(~f=el => {
       Utils.Filename.test(
         Utils.Filename.Exists,
         Utils.Filename.concat(el, "spin"),
       )
     })
  |> List.map(~f=ConfigFile.Generators.parse);
};

let getGenerator = (name, ~source: Source.t) => {
  let generators = listGenerators(source);
  switch (
    List.find(generators, ~f=(el: ConfigFile.Generators.t) =>
      String.equal(el.name, name)
    )
  ) {
  | Some(v) => v
  | None => raise(Errors.GeneratorDoesNotExist(name))
  };
};
