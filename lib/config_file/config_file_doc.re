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

type doc = t;

let path = "spin";

let doc_of_cst = (cst: list(cst)): doc => {
  name:
    Config_file_cst_utils.getUniqueExn(
      cst,
      ~f=
        fun
        | Name(v) => Some(v)
        | _ => None,
    ),
  description:
    Config_file_cst_utils.getUniqueExn(
      cst,
      ~f=
        fun
        | Description(v) => Some(v)
        | _ => None,
    ),
  commands:
    Config_file_cst_utils.get(
      cst,
      ~f=
        fun
        | Command(v) => Some(v)
        | _ => None,
    ),
  startingCommand:
    Config_file_cst_utils.getUnique(
      cst,
      ~f=
        fun
        | Starting_command(v) => Some(v)
        | _ => None,
    ),
  tutorial:
    Config_file_cst_utils.getUnique(
      cst,
      ~f=
        fun
        | Tutorial(v) => Some(v)
        | _ => None,
    ),
};

let t_of_cst = (~useDefaults, ~models, cst: list(cst)) => doc_of_cst(cst);
