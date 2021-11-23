module type S = sig
  val name : string

  val file_list : string list

  val read : string -> string option
end