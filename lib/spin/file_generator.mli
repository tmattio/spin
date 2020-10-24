val copy
  :  context:(string, string) Spin_std.Hashtbl.t
  -> content:string
  -> string
  -> (unit, Spin_error.t) Lwt_result.t

val generate
  :  context:(string, string) Spin_std.Hashtbl.t
  -> content:string
  -> string
  -> (unit, Spin_error.t) Lwt_result.t

val normalize_path : string -> string

val is_binary_file : string -> bool
