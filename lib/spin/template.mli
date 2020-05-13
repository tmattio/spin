type source =
  | Git of string
  | Local_dir of string
  | Official of (module Spin_template.Template)

type example_command =
  { name : string
  ; description : string
  }

type t =
  { name : string
  ; description : string
  ; template_files : (string, string) Hashtbl.t
  ; context : (string, string) Hashtbl.t
  ; pre_gen_actions : Template_actions.t list
  ; post_gen_actions : Template_actions.t list
  ; example_commands : example_command list
  }

val source_of_string : string -> source option

val of_dec
  :  ?use_defaults:bool
  -> ?files:(string, string) Hashtbl.t
  -> ?ignore_configs:bool
  -> ?ignore_actions:bool
  -> ?ignore_example_commands:bool
  -> context:(string, string) Spin_std.Hashtbl.t
  -> Dec_template.t
  -> (t, Spin_error.t) Lwt_result.t

val read
  :  ?use_defaults:bool
  -> ?ignore_configs:bool
  -> ?ignore_actions:bool
  -> ?ignore_example_commands:bool
  -> ?context:(string, string) Spin_std.Hashtbl.t
  -> source
  -> (t, Spin_error.t) Lwt_result.t

val generate : path:string -> t -> (unit, Spin_error.t) Lwt_result.t
