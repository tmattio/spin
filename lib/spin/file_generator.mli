val generate
  :  context:(string, string) Spin_std.Hashtbl.t
  -> content:string
  -> string
  -> (unit, Spin_error.t) Lwt_result.t
