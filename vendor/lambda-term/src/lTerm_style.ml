(*
 * lTerm_style.ml
 * --------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

(* +-----------------------------------------------------------------+
   | Colors                                                          |
   +-----------------------------------------------------------------+ *)

type color =
  | Default
  | Index of int
  | RGB of int * int * int

let default = Default
let index n = Index n
let rgb r g b =
  if r < 0 || r > 255 || g < 0 || g > 255 || b < 0 || b > 255 then
    invalid_arg "LTerm_style.rgb"
  else
    RGB(r, g, b)

let black = Index 0
let red = Index 1
let green = Index 2
let yellow = Index 3
let blue = Index 4
let magenta = Index 5
let cyan = Index 6
let white = Index 7
let lblack = Index 8
let lred = Index 9
let lgreen = Index 10
let lyellow = Index 11
let lblue = Index 12
let lmagenta = Index 13
let lcyan = Index 14
let lwhite = Index 15

(* +-----------------------------------------------------------------+
   | Styles                                                          |
   +-----------------------------------------------------------------+ *)

type t = {
  bold : bool option;
  underline : bool option;
  blink : bool option;
  reverse : bool option;
  foreground : color option;
  background : color option;
}

let bold s = s.bold
let underline s = s.underline
let blink s = s.blink
let reverse s = s.reverse
let foreground s = s.foreground
let background s = s.background

let none = {
  bold = None;
  underline = None;
  blink = None;
  reverse = None;
  foreground = None;
  background = None;
}

let merge_field f1 f2 =
  match f2 with
    | Some _ -> f2
    | None -> f1

let merge s1 s2 = {
  bold = merge_field s1.bold s2.bold;
  underline = merge_field s1.underline s2.underline;
  blink = merge_field s1.blink s2.blink;
  reverse = merge_field s1.reverse s2.reverse;
  foreground = merge_field s1.foreground s2.foreground;
  background = merge_field s1.background s2.background;
}

let bool = function
  | Some b -> b
  | None -> false

let color = function
  | Some c -> c
  | None -> Default

let equal s1 s2 =
  (bool s1.bold = bool s2.bold) &&
    (bool s1.underline = bool s2.underline) &&
    (bool s1.blink = bool s2.blink) &&
    (bool s1.reverse = bool s2.reverse) &&
    (color s1.foreground = color s2.foreground) &&
    (color s1.background = color s2.background)
