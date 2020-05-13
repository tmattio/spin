type doc =
  { name : string
  ; description : string
  }

val read_spin_file
  :  (module Spin_template.Template)
  -> (Dec_template.t, Spin_error.t) Result.t

val all : (module Spin_template.Template) list

val all_doc : unit -> (doc list, Spin_error.t) Result.t

val files_with_content
  :  (module Spin_template.Template)
  -> (string * string) list

val of_name : string -> (module Spin_template.Template) option
