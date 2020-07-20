(*
 * lTerm_style.mli
 * ---------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

(** Text styles *)

(** {6 Colors} *)

type color =
    private
  | Default
      (** The default color of the terminal. *)
  | Index of int
      (** A color given by its index. Most terminal have at least 8
          colors. *)
  | RGB of int * int * int
      (** A color given by its three component between 0 and 255. The
          closest color will be used. *)

val default : color
val index : int -> color
val rgb : int -> int -> int -> color
  (** [rgb r g b] raises [Invalid_argument] if one of [r], [g] or [b]
      is not in the range [0..255]. *)

(** {8 Standard colors} *)

val black : color
val red : color
val green : color
val yellow : color
val blue : color
val magenta : color
val cyan : color
val white : color

(** {8 Light colors} *)

val lblack : color
val lred : color
val lgreen : color
val lyellow : color
val lblue : color
val lmagenta : color
val lcyan : color
val lwhite : color

(** {6 Styles} *)

(** Type of text styles. *)
type t = {
  bold : bool option;
  underline : bool option;
  blink : bool option;
  reverse : bool option;
  foreground : color option;
  background : color option;
}

val bold : t -> bool option
val underline : t -> bool option
val blink : t -> bool option
val reverse : t -> bool option
val foreground : t -> color option
val background : t -> color option

val none : t
  (** Style with all fields set to [None]. *)

val merge : t -> t -> t
  (** [merge s1 s2] is [s2] with all undefined fields set to ones of
      [s1]. *)

val equal : t -> t -> bool
  (** [equal s1 s2] returns [true] iff [s1] and [s2] are equal after
      having replaced all [None] fields by [Some false] or [Some
      Default]. *)
