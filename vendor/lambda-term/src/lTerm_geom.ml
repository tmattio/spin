(*
 * lTerm_geom.ml
 * -------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

type size = {
  rows : int;
  cols : int;
}

let rows size = size.rows
let cols size = size.cols

let string_of_size size =
  Printf.sprintf "{ rows = %d; cols = %d }" size.rows size.cols

type coord = {
  row : int;
  col : int;
}

let row size = size.row
let col size = size.col

let string_of_coord coord =
  Printf.sprintf "{ row = %d; col = %d }" coord.row coord.col

type rect = {
  row1 : int;
  col1 : int;
  row2 : int;
  col2 : int;
}

let row1 rect = rect.row1
let col1 rect = rect.col1
let row2 rect = rect.row2
let col2 rect = rect.col2

let size_of_rect rect = { rows = rect.row2 - rect.row1; cols = rect.col2 - rect.col1 }

let string_of_rect rect =
  Printf.sprintf
    "{ row1 = %d; col1 = %d; row2 = %d; col2 = %d }"
    rect.row1 rect.col1 rect.row2 rect.col2

let in_rect rect coord =
  coord.col >= rect.col1 &&
  coord.col < rect.col2 &&
  coord.row >= rect.row1 &&
  coord.row < rect.row2

type horz_alignment =
  | H_align_left
  | H_align_center
  | H_align_right

type vert_alignment =
  | V_align_top
  | V_align_center
  | V_align_bottom

type 'a directions = {
  left : 'a;
  right : 'a;
  up : 'a;
  down : 'a;
}

