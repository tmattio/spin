(*
 * zed_cursor.ml
 * -------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Zed, an editor engine.
 *)

open React

exception Out_of_bounds

type changes= {
  position: int;
  added: int;
  removed: int;
  added_width: int;
  removed_width: int;
}

type action =
  | User_move of int
  | Text_modification of changes (* start, added, removed *)

type t = {
  position : int signal;
  send : action -> unit;
  length : int ref;
  changes :  changes event;
  get_lines : unit -> Zed_lines.t;
  coordinates : (int * int) signal;
  coordinates_display : (int * int) signal;
  line : int signal;
  column : int signal;
  column_display : int signal;
  wanted_column : int signal;
  set_wanted_column : int -> unit;
}

let create length changes get_lines position wanted_column =
  if position < 0 || position > length then raise Out_of_bounds;
  let length = ref length in
  let user_moves, send = E.create () in
  let update_position position action =
    match action with
    | User_move pos -> pos
    | Text_modification changes ->
      let delta = changes.added - changes.removed in
      length := !length + delta;
      if !length < 0 then raise Out_of_bounds;
      (* Move the cursor if it is after the start of the changes. *)
      if position > changes.position then begin
        if delta >= 0 then
          (* Text has been inserted, advance the cursor. *)
          position + delta
        else if position < changes.position - delta  then
          (* Text has been removed and the removed block contains the
             cursor, move it at the beginning of the removed block. *)
          changes.position
        else
          (* Text has been removed before the cursor, move back the
             cursor. *)
          position + delta
      end else
        position
  in
  let text_modifications = E.map (fun x -> Text_modification x) changes in
  let position =
    S.fold update_position position (E.select [user_moves; text_modifications])
  in
  let compute_coordinates_and_display position =
    let lines = get_lines () in
    let index = Zed_lines.line_index lines position in
    let bol= Zed_lines.line_start lines index in
    let column= position - bol in
    let width= Zed_lines.force_width lines bol column in
    (index, column, bol, width)
  in
  let coordinates_and_display= S.map compute_coordinates_and_display position in
  let coordinates = S.map (fun (row, column,_,_)-> (row, column)) coordinates_and_display in
  let coordinates_display = S.map (fun (row,_,_,width)-> (row, width)) coordinates_and_display in
  let line= S.map fst coordinates in
  let column= S.map snd coordinates in
  let column_display= S.map snd coordinates_display in
  let wanted_column, set_wanted_column = S.create wanted_column in
  {
    position;
    send;
    length;
    changes;
    get_lines;
    coordinates;
    coordinates_display;
    line;
    column;
    column_display;
    wanted_column;
    set_wanted_column;
  }

let copy cursor =
  create
    !(cursor.length)
    cursor.changes
    cursor.get_lines
    (S.value cursor.position)
    (S.value cursor.wanted_column)

let position cursor = cursor.position
let get_position cursor = S.value cursor.position
let line cursor = cursor.line
let get_line cursor = S.value cursor.line
let column cursor = cursor.column
let column_display cursor = cursor.column_display
let get_column cursor = S.value cursor.column
let get_column_display cursor = S.value cursor.column_display
let coordinates cursor = cursor.coordinates
let coordinates_display cursor = cursor.coordinates
let get_coordinates cursor = S.value cursor.coordinates
let get_coordinates_display cursor = S.value cursor.coordinates_display
let wanted_column cursor = cursor.wanted_column
let get_wanted_column cursor = S.value cursor.wanted_column
let set_wanted_column cursor column = cursor.set_wanted_column column

let move cursor ?(set_wanted_column=true) delta =
  let new_position = S.value cursor.position + delta in
  if new_position < 0 || new_position > !(cursor.length) then
    raise Out_of_bounds
  else begin
    cursor.send (User_move new_position);
    if set_wanted_column then cursor.set_wanted_column (S.value cursor.column_display)
  end

let goto cursor ?(set_wanted_column=true) position =
  if position < 0 || position > !(cursor.length) then
    raise Out_of_bounds
  else begin
    cursor.send (User_move position);
    if set_wanted_column then cursor.set_wanted_column (S.value cursor.column_display)
  end
