type doc =
  { name : string
  ; description : string
  }

val read_spin_file
  :  (module Template_intf.S)
  -> (Dec_template.t, Spin_error.t) Result.t

val all_doc : (module Template_intf.S) list -> (doc list, Spin_error.t) Result.t

val files_with_content : (module Template_intf.S) -> (string * string) list

val of_name
  :  templates:(module Template_intf.S) list
  -> string
  -> (module Template_intf.S) option
