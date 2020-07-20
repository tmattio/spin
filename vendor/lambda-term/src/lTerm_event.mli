(*
 * lTerm_event.mli
 * ---------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

(** Events *)

(** Event from the terminal. *)
type t =
  | Resize of LTerm_geom.size
      (** The terminal has been resized. *)
  | Key of LTerm_key.t
      (** A key has been pressed. *)
  | Sequence of string
      (** An uninterpreted escape sequence. *)
  | Mouse of LTerm_mouse.t
      (** A mouse button has been pressed. *)

val to_string : t -> string
  (** [to_string event] returns the string representation of the given
      event. *)
