[@deriving of_sexp]
type command = {
  name: string,
  description: string,
};

[@deriving of_sexp]
type startingCommand = {
  command: string,
  args: list(string),
};

[@deriving of_sexp]
type cst =
  | Name(string)
  | Description(string)
  | Command(command)
  | Starting_command(startingCommand)
  | Tutorial(string);

type t = {
  name: string,
  description: string,
  commands: list(command),
  startingCommand: option(startingCommand),
  tutorial: option(string),
};

let path = "spin";

let t_of_cst = (~useDefaults, ~models, cst: list(cst)): t => {
  name:
    ConfigFile__CstUtils.getUniqueExn(
      cst,
      ~f=
        fun
        | Name(v) => Some(v)
        | _ => None,
    ),
  description:
    ConfigFile__CstUtils.getUniqueExn(
      cst,
      ~f=
        fun
        | Description(v) => Some(v)
        | _ => None,
    ),
  commands:
    ConfigFile__CstUtils.get(
      cst,
      ~f=
        fun
        | Command(v) => Some(v)
        | _ => None,
    ),
  startingCommand:
    ConfigFile__CstUtils.getUnique(
      cst,
      ~f=
        fun
        | Starting_command(v) => Some(v)
        | _ => None,
    ),
  tutorial:
    ConfigFile__CstUtils.getUnique(
      cst,
      ~f=
        fun
        | Tutorial(v) => Some(v)
        | _ => None,
    ),
};
