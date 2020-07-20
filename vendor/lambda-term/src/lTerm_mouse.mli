(*
 * lTerm_mouse.mli
 * ---------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

(** Mouse events *)

(** Type of mouse button. *)
type button =
  | Button1
  | Button2
  | Button3
  | Button4
  | Button5
  | Button6
  | Button7
  | Button8
  | Button9

(** Type of mouse click event. *)
type t = {
  control : bool;
  (** Is the control key down ? *)
  meta : bool;
  (** Is the meta key down ? *)
  shift : bool;
  (** Is the shift key down ? *)
  button : button;
  (** Which button have been pressed ? *)
  row : int;
  (** The row at which the mouse was when the button has been
      pressed. *)
  col : int;
  (** The column at which the mouse was when the button has been
      pressed. *)
}

val compare : t -> t -> int
  (** Same as [Pervasives.compare]. *)

val control : t -> bool
val meta : t -> bool
val button : t -> button
val row : t -> int
val col : t -> int
val coord : t -> LTerm_geom.coord

val to_string : t -> string
  (** Returns the string representation of the given mouse event. *)
