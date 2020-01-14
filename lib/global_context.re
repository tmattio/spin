open Jingoo;

/** Global_context represents the user global configuration.

    We encapsulate the Config_file.User module because the we don't want to have dependencies between the config file modules.
 */

type t = {
  name: option(string),
  email: option(string),
  github_username: option(string),
  npm_username: option(string),
};

type field =
  | Name
  | Email
  | Github_username
  | Npm_username;

let make = (~name=?, ~email=?, ~github_username=?, ~npm_username=?, ()) => {
  name,
  email,
  github_username,
  npm_username,
};

let opt_value = (~default, context: option(t), field: field) =>
  switch (context, field) {
  | (Some({name: v}), Name) => Option.value(v, ~default)
  | (Some({email: v}), Email) => Option.value(v, ~default)
  | (Some({github_username: v}), Github_username) =>
    Option.value(v, ~default)
  | (Some({npm_username: v}), Npm_username) => Option.value(v, ~default)
  | (None, _) => default
  };
