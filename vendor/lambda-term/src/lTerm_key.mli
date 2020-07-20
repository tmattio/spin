(*
 * lTerm_key.mli
 * -------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

(** Keys *)

(** Type of key code. *)
type code =
  | Char of Uchar.t
      (** A unicode character. *)
  | Enter
  | Escape
  | Tab
  | Up
  | Down
  | Left
  | Right
  | F1
  | F2
  | F3
  | F4
  | F5
  | F6
  | F7
  | F8
  | F9
  | F10
  | F11
  | F12
  | Next_page
  | Prev_page
  | Home
  | End
  | Insert
  | Delete
  | Backspace

(** Type of key. *)
type t = {
  control : bool;
  (** Is the control key down ? *)
  meta : bool;
  (** Is the meta key down ? *)
  shift : bool;
  (** Is the shift key down ? *)
  code : code;
  (** The code of the key. *)
}

val compare : t -> t -> int
  (** Same as [Pervasives.compare]. *)

val control : t -> bool
val meta : t -> bool
val code : t -> code

val to_string : t -> string
  (** Returns the string representation of the given key. *)

val to_string_compact : t -> string
  (** Returns the string representation of the given key in the form
      "C-M-a". *)
