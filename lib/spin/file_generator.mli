val copy
  :  context:(string, string) Hashtbl.t
  -> content:string
  -> string
  -> (unit, Spin_error.t) Result.t

val generate
  :  context:(string, string) Hashtbl.t
  -> content:string
  -> string
  -> (unit, Spin_error.t) Result.t

val normalize_path : string -> string

val is_binary_file : string -> bool
