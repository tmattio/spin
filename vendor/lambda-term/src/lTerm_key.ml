(*
 * lTerm_key.ml
 * ------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

(* little hack to maintain 4.02.3 compat with warnings *)
module String = struct
  [@@@ocaml.warning "-3-32"]
  let lowercase_ascii =  StringLabels.lowercase
  include String
end

type code =
  | Char of Uchar.t
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

type t = {
  control : bool;
  meta : bool;
  shift : bool;
  code : code;
}

let compare = compare

let control key = key.control
let meta key = key.meta
let code key = key.code

let string_of_code = function
  | Char ch -> Printf.sprintf "Char 0x%02x" (Uchar.to_int ch)
  | Enter -> "Enter"
  | Escape -> "Escape"
  | Tab -> "Tab"
  | Up -> "Up"
  | Down -> "Down"
  | Left -> "Left"
  | Right -> "Right"
  | F1 -> "F1"
  | F2 -> "F2"
  | F3 -> "F3"
  | F4 -> "F4"
  | F5 -> "F5"
  | F6 -> "F6"
  | F7 -> "F7"
  | F8 -> "F8"
  | F9 -> "F9"
  | F10 -> "F10"
  | F11 -> "F11"
  | F12 -> "F12"
  | Next_page -> "Next_page"
  | Prev_page -> "Prev_page"
  | Home -> "Home"
  | End -> "End"
  | Insert -> "Insert"
  | Delete -> "Delete"
  | Backspace -> "Backspace"

let to_string key =
  Printf.sprintf "{ control = %B; meta = %B; shift = %B; code = %s }" key.control key.meta key.shift (string_of_code key.code)

let to_string_compact key =
  let buffer = Buffer.create 32 in
  if key.control then Buffer.add_string buffer "C-";
  if key.meta then Buffer.add_string buffer "M-";
  if key.shift then Buffer.add_string buffer "S-";
  (match key.code with
     | Char ch ->
         let code = Uchar.to_int ch in
         if code <= 255 then
           match Char.chr code with
             | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9'
             | '_' | '(' | ')' | '[' | ']' | '{' | '}'
             | '#' | '~' | '&' | '$' | '*' | '%'
             | '!' | '?' | ',' | ';' | ':' | '/' | '\\'
             | '.' | '@' | '=' | '+' | '-' as ch ->
                 Buffer.add_char buffer ch
             | ' ' ->
                 Buffer.add_string buffer "space"
             | _ ->
                 Printf.bprintf buffer "U+%02x" code
         else if code <= 0xffff then
           Printf.bprintf buffer "U+%04x" code
         else
           Printf.bprintf buffer "U+%06x" code
     | Next_page ->
         Buffer.add_string buffer "next"
     | Prev_page ->
         Buffer.add_string buffer "prev"
     | code ->
         Buffer.add_string buffer (String.lowercase_ascii (string_of_code code)));
  Buffer.contents buffer
