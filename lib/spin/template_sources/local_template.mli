val read_spin_file : string -> (Dec_template.t, Spin_error.t) Lwt_result.t

val files_with_content : string -> (string * string) list Lwt.t
