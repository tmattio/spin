module type Template = sig
  val name : string

  val file_list : string list

  val read : string -> string option
end

val hello : (module Template)
(** The hello tutorial template *)

val all : (module Template) list
(** List of all of the official spin templates *)
