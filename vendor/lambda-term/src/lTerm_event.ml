(*
 * lTerm_event.ml
 * --------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

type t =
  | Resize of LTerm_geom.size
  | Key of LTerm_key.t
  | Sequence of string
  | Mouse of LTerm_mouse.t

let to_string = function
  | Resize size ->
      Printf.sprintf "Resize %s" (LTerm_geom.string_of_size size)
  | Key key ->
      Printf.sprintf "Key %s" (LTerm_key.to_string key)
  | Sequence seq ->
      Printf.sprintf "Sequence %S" seq
  | Mouse mouse ->
      Printf.sprintf "Mouse %s" (LTerm_mouse.to_string mouse)
