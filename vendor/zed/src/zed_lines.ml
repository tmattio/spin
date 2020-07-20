(*
 * zed_lines.ml
 * ------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Copyright : (c) 2019, ZAN DoYe <zandoye@gmail.com>
 * Licence   : BSD3
 *
 * This file is a part of Zed, an editor engine.
 *)

open Result

exception Out_of_bounds

(* +-----------------------------------------------------------------+
   | Representation                                                  |
   +-----------------------------------------------------------------+ *)

(* Sets are represented by ropes. *)

type line=
  {
    length: int;
    width: int;
    width_info: int array;
  }

type t =
  | String of line
      (* [String len] is a string of length [len] without newline
         character. *)
  | Return
      (* A newline character. *)
  | Concat of t * t * int * int * int
      (* [Concat(t1, t2, len, count, depth)] *)

(* +-----------------------------------------------------------------+
   | Basic functions                                                 |
   +-----------------------------------------------------------------+ *)

let empty_line ()= { length= 0; width= 0; width_info= [||] }

let length = function
  | String line -> line.length
  | Return -> 1
  | Concat(_, _, len, _, _) -> len

let count = function
  | String _ -> 0
  | Return -> 1
  | Concat(_, _, _, count, _) -> count

let depth = function
  | String _ | Return -> 0
  | Concat(_, _, _, _, d) -> d

let empty = String (empty_line ())

let unsafe_width ?(tolerant=false) set idx len=
  let start= idx
  and len_all= len
  and acc=
    if tolerant then
      fun a b-> (+)
        (if a < 0 then 1 else a)
        (if b < 0 then 1 else b)
    else
      (+)
  in
  let rec unsafe_width set idx len=
    if len = 0 then
      Ok 0
    else
      match set with
      | Return-> Error (start + len_all - len)
      | String line->
        Ok (Array.fold_left acc 0 (Array.sub line.width_info idx len))
      | Concat (set1, set2, _,_,_)->
        let len1= length set1 in
        if idx + len <= len1 then
          unsafe_width set1 idx len
        else if idx >= len1 then
          unsafe_width set2 (idx-len1) len
        else
          let r1= unsafe_width set1 idx (len1 - idx)
          and r2= unsafe_width set2 0 (len - len1 + idx) in
          match r1, r2 with
          | Error ofs, _-> Error ofs
          | Ok _, Error ofs-> Error ofs
          | Ok w1, Ok w2-> Ok (w1 + w2)
  in
  unsafe_width set idx len

let width ?(tolerant=false) set idx len =
  if idx < 0 || len < 0 || idx + len > length set then
    raise Out_of_bounds
  else
    unsafe_width ~tolerant set idx len

let force_width set idx len=
  let acc a b= (+)
    (if a < 0 then 1 else a)
    (if b < 0 then 1 else b)
  in
  let rec force_width set idx len=
    if len = 0 then
      0
    else
      match set with
      | Return-> 0
      | String line->
        Array.fold_left acc 0 (Array.sub line.width_info idx len)
      | Concat (set1, set2, _,_,_)->
        let len1= length set1 in
        if idx + len <= len1 then
          force_width set1 idx len
        else if idx >= len1 then
          force_width set2 (idx-len1) len
        else
          let r1= force_width set1 idx (len1 - idx)
          and r2= force_width set2 0 (len - len1 + idx) in
          r1 + r2
  in
  if idx < 0 || len < 0 || idx + len > length set then
    raise Out_of_bounds
  else
    force_width set idx len

(* +-----------------------------------------------------------------+
   | Offset/line resolution                                          |
   +-----------------------------------------------------------------+ *)

let rec line_index_rec set ofs acc =
  match set with
  | String _ ->
    acc
  | Return ->
    if ofs = 0 then
      acc
    else
      acc + 1
  | Concat(s1, s2, _, _, _) ->
    let len1 = length s1 in
    if ofs < len1 then
      line_index_rec s1 ofs acc
    else
      line_index_rec s2 (ofs - len1) (acc + count s1)

let line_index set ofs =
  if ofs < 0 || ofs > length set then
    raise Out_of_bounds
  else
    line_index_rec set ofs 0

let rec line_start_rec set idx acc =
  match set with
  | String _ ->
    acc
  | Return ->
    if idx = 0 then
      acc
    else
      acc + 1
  | Concat(s1, s2, _, _, _) ->
    let count1 = count s1 in
    if idx <= count1 then
      line_start_rec s1 idx acc
    else
      line_start_rec s2 (idx - count1) (acc + length s1)

let line_start set idx =
  if idx < 0 || idx > count set then
    raise Out_of_bounds
  else
    line_start_rec set idx 0

let line_stop set idx =
  if idx = count set
  then length set
  else line_start set (idx + 1) - 1

let line_length set idx =
  line_stop set idx - line_start set idx


(* +-----------------------------------------------------------------+
   | Operations on sets                                              |
   +-----------------------------------------------------------------+ *)

let concat set1 set2 =
  Concat(
    set1, set2,
    length set1 + length set2,
    count set1 + count set2,
    1 + max (depth set1) (depth set2))

let append_line l1 l2=
  { length= l1.length + l2.length;
    width= l1.width + l2.width;
    width_info= Array.append l1.width_info l2.width_info
  }

let append set1 set2 =
  match set1, set2 with
  | String {length= 0;_}, _ -> set2
  | _, String {length= 0;_} -> set1
  | String l1, String l2 -> String (append_line l1 l2)
  | String l1, Concat(String l2, set, len, count, h) ->
    Concat(String (append_line l1 l2), set, len + l1.length, count, h)
  | Concat(set, String l1, len, count, h), String l2 ->
    Concat(set, String(append_line l1 l2), len + l2.length, count, h)
  | _ ->
    let d1 = depth set1 and d2 = depth set2 in
    if d1 > d2 + 2 then begin
      match set1 with
      | String _ | Return ->
        assert false
      | Concat(set1_1, set1_2, _, _, _) ->
        if depth set1_1 >= depth set1_2 then
          concat set1_1 (concat set1_2 set2)
        else begin
          match set1_2 with
          | String _ | Return ->
            assert false
          | Concat(set1_2_1, set1_2_2, _, _, _) ->
            concat (concat set1_1 set1_2_1) (concat set1_2_2 set2)
        end
    end else if d2 > d1 + 2 then begin
      match set2 with
      | String _ | Return ->
        assert false
      | Concat(set2_1, set2_2, _, _, _) ->
        if depth set2_2 >= depth set2_1 then
          concat (concat set1 set2_1) set2_2
        else begin
          match set2_1 with
          | String _ | Return ->
            assert false
          | Concat(set2_1_1, set2_1_2, _, _, _) ->
            concat (concat set1 set2_1_1) (concat set2_1_2 set2_2)
        end
    end else
      concat set1 set2

let rec unsafe_sub set idx len =
  match set with
  | String line ->
    let length= len in
    let width_info= Array.sub line.width_info idx length in
    let width= Array.fold_left (+) 0 width_info in
    String { length; width; width_info }
  | Return ->
    if len = 1 then
      Return
    else
      String (empty_line ())
  | Concat(set_l, set_r, len', _, _) ->
    let len_l = length set_l in
    if len = len' then
      set
    else if idx >= len_l then
      unsafe_sub set_r (idx - len_l) len
    else if idx + len <= len_l then
      unsafe_sub set_l idx len
    else
      append
        (unsafe_sub set_l idx (len_l - idx))
        (unsafe_sub set_r 0 (len - len_l + idx))

let sub set idx len =
  if idx < 0 || len < 0 || idx + len > length set then
    raise Out_of_bounds
  else
    unsafe_sub set idx len

let break set ofs =
  let len = length set in
  if ofs < 0 || ofs > len then
    raise Out_of_bounds
  else
    (unsafe_sub set 0 ofs, unsafe_sub set ofs (len - ofs))

let insert set ofs set' =
  let set1, set2 = break set ofs in
  append set1 (append set' set2)

let remove set ofs len =
  append (sub set 0 ofs) (sub set (ofs + len) (length set - ofs - len))

let replace set ofs len repl =
  append (sub set 0 ofs) (append repl (sub set (ofs + len) (length set - ofs - len)))

(* +-----------------------------------------------------------------+
   | Sets from ropes                                                 |
   +-----------------------------------------------------------------+ *)

let of_rope rope =
  let calc_widths widths=
    let width_info= widths |> List.rev |> Array.of_list in
    let width= Array.fold_left (+) 0 width_info in
    (width, width_info)
  in
  let rec loop zip (length, widths) acc =
    if Zed_rope.Zip.at_eos zip then
      let width, width_info= calc_widths widths in
      append acc (String { length; width; width_info })
    else
      let ch, zip = Zed_rope.Zip.next zip in
      if Uchar.to_int (Zed_char.core ch) = 10 then
        let width, width_info= calc_widths widths in
        loop0 zip (append (append acc (String { length; width; width_info })) Return)
      else
        loop zip (length + 1, Zed_char.width ch::widths) acc
  and loop0 zip acc =
    if Zed_rope.Zip.at_eos zip then
      acc
    else
      let ch, zip = Zed_rope.Zip.next zip in
      if Uchar.to_int (Zed_char.core ch) = 10 then
        loop0 zip (append acc Return)
      else
        loop zip (1, [Zed_char.width ch]) acc
  in
  loop0 (Zed_rope.Zip.make_f rope 0) empty

(* +-----------------------------------------------------------------+
   | Index and width                                                 |
   +-----------------------------------------------------------------+ *)

let get_idx_by_width set row column=
  let start= line_start set row in
  let stop= line_stop set row in
  let rec get idx acc_width=
    if acc_width >= column || idx >= stop then
      idx
    else
      let curr_width= force_width set idx 1 in
      if acc_width + curr_width > column
      then idx (* the width of the current char covers the column *)
      else get (idx+1) (acc_width + curr_width)
  in
  get start 0

