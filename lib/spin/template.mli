type source =
  | Git of string
  | Local_dir of string
  | Official of (module Template_intf.S)

type example_command =
  { name : string
  ; description : string
  }

type t =
  { name : string
  ; description : string
  ; raw_files : string list
  ; parse_binaries : bool
  ; files : (string, string) Hashtbl.t
  ; context : (string, string) Hashtbl.t
  ; pre_gen_actions : Template_actions.t list
  ; post_gen_actions : Template_actions.t list
  ; example_commands : example_command list
  ; source : source
  }

val source_of_string
  :  templates:(module Template_intf.S) list
  -> string
  -> source Option.t

val source_of_dec
  :  templates:(module Template_intf.S) list
  -> Dec_common.Source.t
  -> (source, string) Result.t

val source_to_dec : source -> Dec_common.Source.t

val read_source_spin_file
  :  ?download_git:bool
  -> source
  -> (Dec_template.t, Spin_error.t) Result.t

val read_source_template_files
  :  ?download_git:bool
  -> source
  -> ((string, string) Hashtbl.t, Spin_error.t) Result.t

val read
  :  ?use_defaults:bool
  -> ?context:(string, string) Hashtbl.t
  -> templates:(module Template_intf.S) list
  -> source
  -> (t, Spin_error.t) Result.t

val generate : path:string -> t -> (unit, Spin_error.t) Result.t
