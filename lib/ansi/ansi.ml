open Ansi_common

module type ANSI_IMPL = sig
  val print_string : style list -> string -> unit
  val prerr_string : style list -> string -> unit
  val printf : style list -> ('a, unit, string, unit) format4 -> 'a
  val eprintf : style list -> ('a, unit, string, unit) format4 -> 'a
  val sprintf : style list -> ('a, unit, string) format -> 'a
  val scroll : int -> unit
  val size : unit -> int * int
  val resize : int -> int -> unit
  val save_cursor : unit -> unit
  val restore_cursor : unit -> unit
  val show_cursor : unit -> unit
  val hide_cursor : unit -> unit
  val set_cursor : int -> int -> unit
  val move_cursor : int -> int -> unit
  val move_bol : unit -> unit
  val pos_cursor : unit -> int * int
  val erase : loc -> unit
end

module type S = sig
  include module type of Ansi_common
  include ANSI_IMPL
end

module Make (Impl : ANSI_IMPL) : S = struct
  include Ansi_common
  include Impl
end

module Unix_impl = Make (Ansi_unix)
module Windows_impl = Make (Ansi_win)

module Impl =
  (val match Sys.os_type with
       | "Unix" | "Cygwin" -> (module Unix_impl : S)
       | _ -> (module Windows_impl : S))

include Impl
