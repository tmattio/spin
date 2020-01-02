[@deriving of_sexp]
type command = {
  name: string,
  description: string,
};

[@deriving of_sexp]
type starting_command = {
  command: string,
  args: list(string),
};

[@deriving of_sexp]
type cst =
  | Name(string)
  | Description(string)
  | Command(command)
  | Starting_command(starting_command)
  | Tutorial(string);

type t = {
  name: string,
  description: string,
  commands: list(command),
  starting_command: option(starting_command),
  tutorial: option(string),
};

type doc = t;

let path = "spin";

let doc_of_cst = (cst: list(cst)): doc => {
  name:
    Config_file_cst_utils.get_unique_exn(
      cst,
      ~f=
        fun
        | Name(v) => Some(v)
        | _ => None,
    ),
  description:
    Config_file_cst_utils.get_unique_exn(
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
  starting_command:
    Config_file_cst_utils.get_unique(
      cst,
      ~f=
        fun
        | Starting_command(v) => Some(v)
        | _ => None,
    ),
  tutorial:
    Config_file_cst_utils.get_unique(
      cst,
      ~f=
        fun
        | Tutorial(v) => Some(v)
        | _ => None,
    ),
};

let t_of_cst = (~use_defaults, ~models, cst: list(cst)) => doc_of_cst(cst);
