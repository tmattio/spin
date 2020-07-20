(*
 * zed_lines.mli
 * -------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Zed, an editor engine.
 *)

(** Sets of line positions. *)

(** This module implement sets of line positions. They allow to
    efficiently find the beginning of a line and to convert offset to
    line and column number. *)

open Result

exception Out_of_bounds
  (** Exception raised when trying to access a position outside the
      bounds of a set. *)

type line

type t
  (** Type of sets of line positions. *)

val length : t -> int
  (** Returns the length of the set, i.e. the number of characters in
      the set. *)

val count : t -> int
  (** Returns the number of newlines in the set. *)

val of_rope : Zed_rope.t -> t
  (** [of_rope rope] returns the set of newline positions in [rope]. *)

val empty : t
  (** The empty set. *)

val width : ?tolerant:bool -> t -> int -> int -> (int, int) result
  (** Returns the width of the given string. *)

val force_width : t -> int -> int -> int
  (** Returns the width of the given string. If error encounted, returns the width of the legit part *)

val line_index : t -> int -> int
  (** [line_index set ofs] returns the line number of the line
      containing [ofs]. *)

val line_start : t -> int -> int
  (** [line_start set idx] returns the offset of the beginning of the
      [idx]th line of [set] . *)

val line_stop : t -> int -> int
  (** [line_stop set idx] returns the offset of the end of the
      [idx]th line of [set] . *)

val line_length : t -> int -> int
  (** [line_length set idx] returns the length of the
      [idx]th line of [set] . *)

val append : t -> t -> t
  (** [append s1 s2] concatenates two sets of line positions. *)

val insert : t -> int -> t -> t
  (** [insert set offset set'] inserts [set] at given positon in
      [set'].*)

val remove : t -> int -> int -> t
  (** [remove set offet length] removes [length] characters at
      [offset] in set. *)

val replace : t -> int -> int -> t -> t
  (** [replace set offset length repl] replaces the subset at offset
      [offset] and length [length] by [repl] in [set]. *)

val get_idx_by_width : t -> int -> int -> int
  (** [get_idx_by_width set row column_width] return the offset of the char
      at \[row, column_width\]. *)

