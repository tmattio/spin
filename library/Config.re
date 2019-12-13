type variableDoc('t) = {
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
  let optValue = Sys.getenv(name) |> Option.map(~f=parse);
  let getOpt = () => optValue;
  let get = () => getOpt() |> Option.value(~default);
  let docInfo = {name, doc, default: unparse(default)};
};

let getenvExn = name => {
  let fn = () => {
    switch (Sys.getenv(name)) {
    | Some(env) => env
    | _ => raise(Errors.MissingEnvVar(name))
    };
  };
  Errors.handleErrors(fn);
};

module SPIN_CACHE_DIR =
  EnvVar({
    type t = string;
    let parse = Utils.Filename.ensure_trailing;
    let unparse = Utils.Filename.ensure_trailing;
    let name = "SPIN_CACHE_DIR";
    let doc = "The directory where the templates and other cached data is stored.";
    let default = {
      let home =
        switch (Caml.Sys.os_type) {
        | "Unix" => getenvExn("HOME")
        | _ => getenvExn("APPDATA")
        };
      let cacheDir = Utils.Filename.concat(home, ".cache");
      Utils.Filename.concat(cacheDir, "spin");
    };
  });

let all = () => [SPIN_CACHE_DIR.docInfo];
