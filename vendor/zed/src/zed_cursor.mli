(*
 * zed_cursor.mli
 * --------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Zed, an editor engine.
 *)

(** Cursors *)

(** A cursor is a pointer in an edition buffer. When some text is
    inserted or removed, all cursors after the modification are
    automatically moved accordingly. *)

open React

type t
  (** Type of a cursor. *)

type changes= {
  position: int;
  added: int;
  removed: int;
  added_width: int;
  removed_width: int;
}

exception Out_of_bounds
  (** Exception raised when trying to move a cursor outside the bounds
      of the text it points to. *)

val create : int -> changes event -> (unit -> Zed_lines.t) -> int -> int -> t
  (** [create length changes get_lines position wanted_column] creates
      a new cursor pointing to position [position].

      [length] is the current length of the text the cursor points
      to. It raises {!Out_of_bounds} if [position] is greater than
      [length].

      [changes] is an event which occurs with values of the form
      [(start, added, removed)] when the text changes, with the same
      semantic as {!Zed_edit.changes}.

      [get_lines] is used to retreive the current set of line
      positions of the text. It is used to compute the line and column
      of the cursor.

      [wanted_column] is the column on which the cursor want to be, if
      there is enough room on the line. *)

val copy : t -> t
  (** [copy cursor] creates a copy of the given cursor. The new cursor
      initially points to the same location as [cursor]. *)

val position : t -> int signal
  (** [position cursor] returns the signal holding the current
      position of the given cursor. *)

val get_position : t -> int
  (** [get_position cursor] returns the current position of
      [cursor]. *)

val line : t -> int signal
  (** [line cursor] returns the signal holding the current line on
      which the cursor is. *)

val get_line : t -> int
  (** [get_line cursor] returns the current line of the cursor. *)

val column : t -> int signal
  (** [column cursor] returns the signal holding the current column of
      the cursor. *)

val column_display : t -> int React.signal
  (** [column_display cursor] returns the signal holding the current display column of
      the cursor. *)

val get_column : t -> int
  (** [get_column cursor] returns the current column of the cursor. *)

val get_column_display : t -> int
  (** [get_column_display cursor] returns the current display column of the cursor. *)

val coordinates : t -> (int * int) signal
  (** [coordinates cursor] returns the signal holding the current
      line & column of the cursor. *)

val coordinates_display : t -> (int * int) React.signal
  (** [coordinates cursor] returns the signal holding the current
      line & display column of the cursor. *)

val get_coordinates : t -> int * int
  (** [get_coordinates cursor] returns the
      current line & column of the cursor. *)

val get_coordinates_display : t -> int * int
  (** [get_coordinates_display cursor] returns the
      current line & display column of the cursor. *)

val wanted_column : t -> int signal
  (** [wanted_column cursor] returns the signal holding the column on
      which the cursor wants to be. *)

val get_wanted_column : t -> int
  (** [get_wanted_column cursor] returns the column on which the
      cursor wants to be. *)

val set_wanted_column : t -> int -> unit
  (** [set_wanted_column cursor] sets the column on which the cursor
      want to be. *)

val goto : t -> ?set_wanted_column : bool -> int -> unit
  (** [goto cursor position] moves the given cursor to the given
      position. It raises {!Out_of_bounds} if [position] is outside
      the bounds of the text. If [set_wanted_column] is [true] (the
      default), then the wanted column will be set to the column of
      the cursor at given position. *)

val move : t -> ?set_wanted_column : bool -> int -> unit
  (** [move cursor delta] moves the given cursor by the given number
      of characters. It raises {!Out_of_bounds} if the result is
      outside the bounds of the text. *)
