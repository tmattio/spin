type variable_doc('t) = {
  name: string,
  doc: string,
  default: string,
};

module EnvVar =
       (
         M: {
           type t;
           let name: string;
           let doc: string;
           let default: t;
           let parse: string => t;
           let unparse: t => string;
         },
       ) => {
  include M;
  let opt_value = Sys.getenv(name) |> Option.map(~f=parse);
  let get_opt = () => opt_value;
  let get = () => get_opt() |> Option.value(~default);
  let doc_info = {name, doc, default: unparse(default)};
};

let getenv_exn = name => {
  let fn = () => {
    switch (Sys.getenv(name)) {
    | Some(env) => env
    | _ => raise(Errors.Missing_env_var(name))
    };
  };
  Errors.handle_errors(fn);
};

module SPIN_CACHE_DIR =
  EnvVar({
    type t = string;
    let parse = Utils.Filename.ensure_trailing;
    let unparse = Utils.Filename.ensure_trailing;
    let name = "SPIN_CACHE_DIR";
    let doc = "The directory where the cached data is stored.";
    let default = {
      let home =
        switch (Caml.Sys.os_type) {
        | "Unix" => getenv_exn("HOME")
        | _ => getenv_exn("APPDATA")
        };
      let cache_dir = Utils.Filename.concat(home, ".cache");
      Utils.Filename.concat(cache_dir, "spin");
    };
  });

module SPIN_CONFIG_DIR =
  EnvVar({
    type t = string;
    let parse = Utils.Filename.ensure_trailing;
    let unparse = Utils.Filename.ensure_trailing;
    let name = "SPIN_CONFIG_DIR";
    let doc = "The directory where the configuration files are stored.";
    let default = {
      let home =
        switch (Caml.Sys.os_type) {
        | "Unix" => getenv_exn("HOME")
        | _ => getenv_exn("APPDATA")
        };
      let config_dir = Utils.Filename.concat(home, ".config");
      Utils.Filename.concat(config_dir, "spin");
    };
  });

let read_global_context = () => {
  let dir = SPIN_CONFIG_DIR.get();
  let filepath = Config_file.User.path(dir);

  if (Utils.Filename.test(Utils.Filename.Exists, filepath)) {
    let user_config = Config_file.User.parse(dir);
    let context =
      Global_context.make(
        ~name=?user_config.name,
        ~email=?user_config.email,
        ~github_username=?user_config.github_username,
        ~npm_username=?user_config.npm_username,
        (),
      );

    Some(context);
  } else {
    None;
  };
};

let all = () => [SPIN_CACHE_DIR.doc_info, SPIN_CONFIG_DIR.doc_info];
