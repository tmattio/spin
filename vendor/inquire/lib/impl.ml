module type M = sig
  val make_prompt : string -> (Zed_char.t * LTerm_style.t) array

  val make_error : string -> (Zed_char.t * LTerm_style.t) array

  val make_select
    :  current:int
    -> string list
    -> (Zed_char.t * LTerm_style.t) array
end
