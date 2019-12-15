let getProjectRoot = () => {
  ConfigFile.Project.path
  |> Utils.Sys.get_parent_file
  |> Option.map(~f=Caml.Filename.dirname);
};

let getProjectConfig = () => {
  switch (getProjectRoot()) {
  | Some(f) => ConfigFile.Project.parse(f)
  | None => raise(Errors.CurrentDirectoryNotASpinProject)
  };
};

let getProjectDoc = () => {
  switch (getProjectRoot()) {
  | Some(f) => ConfigFile.Project.parse_doc(f)
  | None => raise(Errors.CurrentDirectoryNotASpinProject)
  };
};

let listGenerators = (source: Source.t): list(ConfigFile.Generators.doc) => {
  let localPath = Source.toLocalPath(source);
  let generatorsDir = Utils.Filename.concat(localPath, "generators");

  Utils.Sys.ls_dir(~recursive=false, generatorsDir)
  |> List.filter(~f=el => {
       Utils.Filename.test(
         Utils.Filename.Exists,
         Utils.Filename.concat(el, "spin"),
       )
     })
  |> List.map(~f=ConfigFile.Generators.parse_doc);
};

let getGenerator = (name, ~source: Source.t) => {
  let generators = listGenerators(source);
  switch (
    List.find(generators, ~f=(el: ConfigFile.Generators.doc) =>
      String.equal(el.name, name)
    )
  ) {
  | Some(v) => v
  | None => raise(Errors.GeneratorDoesNotExist(name))
  };
};
