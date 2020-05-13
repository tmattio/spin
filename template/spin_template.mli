module type Template = sig
  val name : string

  val file_list : string list

  val read : string -> string option
end

module Bs_react : Template

module Cli : Template

module Lib : Template

module Bin : Template

module Ppx : Template

val all : (module Template) list
(** List of all of the official spin templates *)
