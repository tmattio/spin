(*
 * lTerm_ui.mli
 * ------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

(** High level function for writing full-screen applications *)

type t
  (** Type of a user interface. *)

val create : LTerm.t -> ?save_state : bool -> (t -> LTerm_draw.matrix -> unit) -> t Lwt.t
  (** [create term ?save_state draw] creates a new user
      interface. [draw] is used to draw the user interface. If
      [save_state] is [true] (the default) then the state of the
      terminal is saved. *)

val quit : t -> unit Lwt.t
  (** [quit ()] quit the given ui and restore the terminal state. *)

val size : t -> LTerm_geom.size
  (** [size ui] returns the current size of the terminal used by the
      given user-interface. It is updated by {!wait}. *)

val draw : t -> unit
  (** [draw ui] enqueue a draw operation for the given UI. *)

val cursor_visible : t -> bool
  (** [cursor_visible ui] returns [true] if the cursor is displayed in
      the UI. It is initially not visible. *)

val set_cursor_visible : t -> bool -> unit
  (** [set_cursor_visible ui visible] sets the cursor visible
      state. *)

val cursor_position : t -> LTerm_geom.coord
  (** [cursor_position ui] returns the position of the cursor inside
      the UI. *)

val set_cursor_position : t -> LTerm_geom.coord -> unit
  (** [set_cursor_position ui coord] sets the position of the cursor
      inside the UI. *)

val wait : t -> LTerm_event.t Lwt.t
  (** [wait ui] wait for an event. *)
