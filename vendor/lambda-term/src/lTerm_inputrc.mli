(*
 * lTerm_inputrc.mli
 * -----------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

(** Loading of key bindings *)

exception Parse_error of string * int * string
  (** [Parse_error(source, line, message)] is raised when the inputrc
      file contains errors. *)

val load : ?file : string -> unit -> unit Lwt.t
  (** [load ?file ()] loads key bindings from [file], which defaults
      to ~/.config/.lambda-term-inputrc, if it exists. *)

val default : string
  (** The name of the default key bindings file,
      i.e. ~/.config/.lambda-term-inputrc
      or the legacy location ~/.lambda-term-inputrc, if it exists *)
