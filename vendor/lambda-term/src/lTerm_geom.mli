(*
 * lTerm_geom.mli
 * --------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

(** Common types. *)

(** Type of sizes. *)
type size = {
  rows : int;
  cols : int;
}

val rows : size -> int
val cols : size -> int

val string_of_size : size -> string
  (** Returns the string representation of the given size. *)

(** Type of coordinates. *)
type coord = {
  row : int;
  col : int;
}

val row : coord -> int
val col : coord -> int

val string_of_coord : coord -> string
  (** Returns the string representation of the given coordinates. *)

(** Type of rectangles. *)
type rect = {
  row1 : int;
  col1 : int;
  row2 : int;
  col2 : int;
}

val row1 : rect -> int
val col1 : rect -> int
val row2 : rect -> int
val col2 : rect -> int

val size_of_rect : rect -> size
  (** Returns the size of a rectangle. *)

val string_of_rect : rect -> string
  (** Returns the string representation of the given rectangle. *)

val in_rect : rect -> coord -> bool
  (** Test if coord is within rect *)

(** Horizontal alignment. *)
type horz_alignment =
  | H_align_left
  | H_align_center
  | H_align_right

(** Vertical alignement. *)
type vert_alignment =
  | V_align_top
  | V_align_center
  | V_align_bottom

(** Movement directions. *)
type 'a directions = {
  left : 'a;
  right : 'a;
  up : 'a;
  down : 'a;
}

