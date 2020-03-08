[@deriving of_sexp]
type cst =
  | Name(string)
  | Description(string);

type t = {
  name: string,
  description: string,
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
};

let t_of_cst = (~use_defaults, ~models, ~global_context, cst: list(cst)) =>
  doc_of_cst(cst);
