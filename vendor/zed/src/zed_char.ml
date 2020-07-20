(*
 * zed_char.ml
 * -----------
 * Copyright : (c) 2019, ZAN DoYe <zandoye@gmail.com>
 * Licence   : BSD3
 *
 * This file is a part of Zed, an editor engine.
 *)


open Result

type t= Zed_utf8.t

type char_prop=
  | Printable of int
  | Other
  | Null

let to_raw= Zed_utf8.explode
let to_array t= Array.of_list (Zed_utf8.explode t)

let zero= String.make 1 (Char.chr 0)

let core t= Zed_utf8.unsafe_extract t 0
let combined t= List.tl (Zed_utf8.explode t)

let prop_uChar uChar=
  match Uucp.Break.tty_width_hint uChar with
  | -1 -> Other
  | 0->
    if Uchar.to_int uChar = 0
    then Null
    else Printable 0
  | w-> Printable w

let prop t= prop_uChar (Zed_utf8.unsafe_extract t 0)

let is_printable uChar=
  match prop_uChar uChar with
  | Printable _ -> true
  | _-> false

let is_printable_core uChar=
  match prop_uChar uChar with
  | Printable w when w > 0 -> true
  | _-> false

let is_combining_mark uChar=
  match prop_uChar uChar with
  | Printable w when w = 0 -> true
  | _-> false

let length= Zed_utf8.length
let size= length

let width t= Uucp.Break.tty_width_hint (Zed_utf8.unsafe_extract t 0)

let out_of_range t i= i < 0 || i >= size t
let get= Zed_utf8.get

let get_opt t i=
  try Some (get t i)
  with _-> None

let append ch mark=
  match prop_uChar mark with
  | Printable 0-> ch ^ (Zed_utf8.singleton mark)
  | _-> failwith "combining mark expected"

let compare_core t1 t2=
  let core1= Zed_utf8.unsafe_extract t1 0
  and core2= Zed_utf8.unsafe_extract t2 0 in
  Uchar.compare core1 core2

let compare_raw= Zed_utf8.compare

let compare= compare_raw

let mix_uChar zChar uChar=
  match prop_uChar uChar with
  | Printable 0->
    Ok (zChar ^ (Zed_utf8.singleton uChar))
  | _->
    Error (Zed_utf8.singleton uChar)

let first_core ?(trim=false) uChars=
  let rec aux uChars=
    match uChars with
    | []-> None, []
    | uChar::tl->
      let prop= prop_uChar uChar in
      match prop with
      | Printable w->
        if w > 0
        then Some (prop, uChar), tl
        else aux tl
      | Other-> Some (prop, uChar), tl
      | Null-> Some (prop, uChar), tl
  in
  match uChars with
  | []-> None, []
  | uChar::_->
    if not trim && is_combining_mark uChar then
      None, uChars
    else
      aux uChars

let rec subsequent uChars=
  match uChars with
  | []-> [], []
  | uChar::tl->
    let prop= prop_uChar uChar in
    match prop with
    | Printable w->
      if w > 0 then
        [], uChars
      else
        let seq, remain= subsequent tl in
        uChar :: seq, remain
    | _-> [], uChars

let of_uChars ?(trim=false) ?(indv_combining=true) uChars=
  match uChars with
  | []-> None, []
  | uChar::tl->
    match first_core ~trim uChars with
    | None, _->
      if indv_combining then
        Some (Zed_utf8.singleton uChar), tl
      else
        None, uChars
    | Some (Printable _w, uChar), tl->
      let combined, tl= subsequent tl in
      Some (Zed_utf8.implode (uChar::combined)), tl
    | Some (Null, uChar), tl->
      Some (Zed_utf8.singleton uChar) ,tl
    | Some (Other, uChar), tl->
      Some (Zed_utf8.singleton uChar) ,tl

let zChars_of_uChars ?(trim=false) ?(indv_combining=true) uChars=
  let rec aux zChars uChars=
    match of_uChars ~trim ~indv_combining uChars with
    | None, tl-> List.rev zChars, tl
    | Some zChar, tl-> aux (zChar::zChars) tl
  in
  aux [] uChars

external id : 'a -> 'a = "%identity"
let unsafe_of_utf8 : string -> t=
  fun str-> if String.length str > 0
    then str
    else failwith "malformed Zed_char sequence"
let of_utf8 ?(indv_combining=true) str=
  match of_uChars ~indv_combining (Zed_utf8.explode str) with
  | Some zChar, []-> zChar
  | _-> failwith "malformed Zed_char sequence"

let to_utf8 : t -> string= id

let unsafe_of_char c=
  Zed_utf8.singleton (Uchar.of_char c)

let unsafe_of_uChar uChar= Zed_utf8.singleton uChar

let for_all= Zed_utf8.for_all
let iter= Zed_utf8.iter

