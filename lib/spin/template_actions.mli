type command =
  { name : string
  ; args : string list
  }

type action =
  | Run of command
  | Install
  | Build
  | Refmt of string list

type t =
  { message : string option
  ; actions : action list
  }

val action_run
  : (root_path:string -> command -> (unit, Spin_error.t) result) ref

val action_refmt
  : (root_path:string -> string list -> (unit, Spin_error.t) result) ref

val action_build : (root_path:string -> (unit, Spin_error.t) result) ref

val action_install : (root_path:string -> (unit, Spin_error.t) result) ref

val of_dec : context:(string, string) Hashtbl.t -> Dec_template.Actions.t -> t

val of_decs_with_condition
  :  context:(string, string) Hashtbl.t
  -> Dec_template.Actions.t list
  -> (t list, Spin_error.t) Result.t

val run : path:string -> t -> (unit, Spin_error.t) Result.t
