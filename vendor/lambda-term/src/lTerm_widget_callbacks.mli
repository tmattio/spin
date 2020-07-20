(*
 * lTerm_widget_callbacks.mli
 * ----------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

type switch
  (** Switches are used to stop signals. *)

type 'a callbacks

val create : unit -> 'a callbacks

val register : switch option -> 'a callbacks -> 'a -> unit
  (** *)

val stop : switch -> unit
  (** *)

val exec_callbacks : ('a -> unit) callbacks -> 'a -> unit
  (** [apply_callbacks callbacks x] *)

val exec_filters : ('a -> bool) callbacks -> 'a -> bool

