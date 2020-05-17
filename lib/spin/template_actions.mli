type command =
  { name : string
  ; args : string list
  }

type action =
  | Run of command
  | Refmt of string list

type t =
  { message : string option
  ; actions : action list
  }

val of_dec
  :  context:(string, string) Hashtbl.t
  -> Dec_template.Actions.t
  -> t Lwt.t

val of_decs_with_condition
  :  context:(string, string) Hashtbl.t
  -> Dec_template.Actions.t list
  -> (t list, Spin_error.t) Lwt_result.t

val run : path:string -> t -> (unit, Spin_error.t) Lwt_result.t
