(*
 * gen_color_mappings.ml
 * ---------------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

(* This program generates the contents of the file
   lTerm_color_mappings.ml which contains tables used to convert RGB
   colors to indexes. *)

(* +-----------------------------------------------------------------+
   | Mapping generation                                              |
   +-----------------------------------------------------------------+ *)

type map = {
  count_r : int;
  count_g : int;
  count_b : int;
  index_r : string;
  index_g : string;
  index_b : string;
  map : string;
}

module Int_set = Set.Make(struct type t = int let compare x y = x - y end)

let reindex set =
  let indexes = String.make 256 '\x00' in
  let rec loop idx prev = function
    | [] ->
        for i = prev to 255 do
          indexes.[i] <- char_of_int idx
        done;
        indexes
    | next :: rest ->
        let middle = (prev + next) / 2 in
        for i = prev to middle do
          indexes.[i] <- char_of_int idx
        done;
        let idx = idx + 1 in
        for i = middle + 1 to next - 1 do
          indexes.[i] <- char_of_int idx
        done;
        loop idx next rest
  in
  match Int_set.elements set with
    | [] ->
        assert false
    | n :: rest ->
        loop 0 n rest

let pi = 4. *. atan 1.

let hsv_of_rgb (r, g, b) =
  let r = float r /. 255. and g = float g /. 255. and b = float b /. 255. in
  let min = min r (min g b) and max = max r (max g b) in
  let h =
    if min = max then
      0.
    else if max = r then
      mod_float (60. *. (g -. b) /. (max -. min) +. 360.) 360.
    else if max = g then
      60. *. (b -. r) /. (max -. min) +. 120.
    else
      60. *. (r -. g) /. (max -. min) +. 240.
  and s =
    if max = 0. then
      0.
    else
      1. -. min /. max
  and v =
    max
  in
  (h *. pi /. 180., s, v)

let sqr x = x *. x

let dist color1 color2 =
  let (h1, s1, v1) = hsv_of_rgb color1 and (h2, s2, v2) = hsv_of_rgb color2 in
  let x1 = s1 *. cos h1 and y1 = s1 *. sin h1 and z1 = v1 in
  let x2 = s2 *. cos h2 and y2 = s2 *. sin h2 and z2 = v2 in
  sqr (x1 -. x2) +. sqr (y1 -. y2) +. sqr (z1 -. z2)

let make_map start colors =
  let rec loop idx acc = function
    | [] ->
        acc
    | n :: rest ->
        loop (idx + 1) ((idx, ((n lsr 16) land 0xff, (n lsr 8) land 0xff, n land 0xff)) :: acc) rest
  in
  let colors = loop start [] colors in
  let set_r, set_g, set_b =
    List.fold_left
      (fun (set_r, set_g, set_b) (idx, (r, g, b)) ->
         (Int_set.add r set_r,
          Int_set.add g set_g,
          Int_set.add b set_b))
      (Int_set.empty,
       Int_set.empty,
       Int_set.empty)
      colors
  in
  let count_r = Int_set.cardinal set_r
  and count_g = Int_set.cardinal set_g
  and count_b = Int_set.cardinal set_b
  and index_r = reindex set_r
  and index_g = reindex set_g
  and index_b = reindex set_b
  and value_r = Array.of_list (Int_set.elements set_r)
  and value_g = Array.of_list (Int_set.elements set_g)
  and value_b = Array.of_list (Int_set.elements set_b) in
  let map = String.make (count_r * count_g * count_b) '\x00' in
  for ir = 0 to count_r - 1 do
    for ig = 0 to count_g - 1 do
      for ib = 0 to count_b - 1 do
        let color = (value_r.(ir), value_g.(ig), value_b.(ib)) in
        let rec loop min idx_of_min = function
          | [] ->
              idx_of_min
          | (idx, color') :: rest ->
              let d = dist color color' in
              if d < min then
                loop d idx rest
              else
                loop min idx_of_min rest
        in
        map.[ir + count_r * (ig + count_g * ib)] <- char_of_int (loop max_float 0 colors)
      done
    done
  done;
  { count_r; count_g; count_b; index_r; index_g; index_b; map }

(* +-----------------------------------------------------------------+
   | Color tables                                                    |
   +-----------------------------------------------------------------+ *)

let colors_16 = make_map 0 [
  0x000000; 0xcd0000; 0x00cd00; 0xcdcd00; 0x0000ee; 0xcd00cd; 0x00cdcd; 0xe5e5e5;
  0x7f7f7f; 0xff0000; 0x00ff00; 0xffff00; 0x5c5cff; 0xff00ff; 0x00ffff; 0xffffff;
]

let colors_88 = make_map 16 [
  0x000000; 0x00008b; 0x0000cd; 0x0000ff; 0x008b00; 0x008b8b; 0x008bcd; 0x008bff;
  0x00cd00; 0x00cd8b; 0x00cdcd; 0x00cdff; 0x00ff00; 0x00ff8b; 0x00ffcd; 0x00ffff;
  0x8b0000; 0x8b008b; 0x8b00cd; 0x8b00ff; 0x8b8b00; 0x8b8b8b; 0x8b8bcd; 0x8b8bff;
  0x8bcd00; 0x8bcd8b; 0x8bcdcd; 0x8bcdff; 0x8bff00; 0x8bff8b; 0x8bffcd; 0x8bffff;
  0xcd0000; 0xcd008b; 0xcd00cd; 0xcd00ff; 0xcd8b00; 0xcd8b8b; 0xcd8bcd; 0xcd8bff;
  0xcdcd00; 0xcdcd8b; 0xcdcdcd; 0xcdcdff; 0xcdff00; 0xcdff8b; 0xcdffcd; 0xcdffff;
  0xff0000; 0xff008b; 0xff00cd; 0xff00ff; 0xff8b00; 0xff8b8b; 0xff8bcd; 0xff8bff;
  0xffcd00; 0xffcd8b; 0xffcdcd; 0xffcdff; 0xffff00; 0xffff8b; 0xffffcd; 0xffffff;
  0x2e2e2e; 0x5c5c5c; 0x737373; 0x8b8b8b; 0xa2a2a2; 0xb9b9b9; 0xd0d0d0; 0xe7e7e7;
]

let colors_256 = make_map 16 [
  0x000000; 0x00005f; 0x000087; 0x0000af; 0x0000d7; 0x0000ff; 0x005f00; 0x005f5f;
  0x005f87; 0x005faf; 0x005fd7; 0x005fff; 0x008700; 0x00875f; 0x008787; 0x0087af;
  0x0087d7; 0x0087ff; 0x00af00; 0x00af5f; 0x00af87; 0x00afaf; 0x00afd7; 0x00afff;
  0x00d700; 0x00d75f; 0x00d787; 0x00d7af; 0x00d7d7; 0x00d7ff; 0x00ff00; 0x00ff5f;
  0x00ff87; 0x00ffaf; 0x00ffd7; 0x00ffff; 0x5f0000; 0x5f005f; 0x5f0087; 0x5f00af;
  0x5f00d7; 0x5f00ff; 0x5f5f00; 0x5f5f5f; 0x5f5f87; 0x5f5faf; 0x5f5fd7; 0x5f5fff;
  0x5f8700; 0x5f875f; 0x5f8787; 0x5f87af; 0x5f87d7; 0x5f87ff; 0x5faf00; 0x5faf5f;
  0x5faf87; 0x5fafaf; 0x5fafd7; 0x5fafff; 0x5fd700; 0x5fd75f; 0x5fd787; 0x5fd7af;
  0x5fd7d7; 0x5fd7ff; 0x5fff00; 0x5fff5f; 0x5fff87; 0x5fffaf; 0x5fffd7; 0x5fffff;
  0x870000; 0x87005f; 0x870087; 0x8700af; 0x8700d7; 0x8700ff; 0x875f00; 0x875f5f;
  0x875f87; 0x875faf; 0x875fd7; 0x875fff; 0x878700; 0x87875f; 0x878787; 0x8787af;
  0x8787d7; 0x8787ff; 0x87af00; 0x87af5f; 0x87af87; 0x87afaf; 0x87afd7; 0x87afff;
  0x87d700; 0x87d75f; 0x87d787; 0x87d7af; 0x87d7d7; 0x87d7ff; 0x87ff00; 0x87ff5f;
  0x87ff87; 0x87ffaf; 0x87ffd7; 0x87ffff; 0xaf0000; 0xaf005f; 0xaf0087; 0xaf00af;
  0xaf00d7; 0xaf00ff; 0xaf5f00; 0xaf5f5f; 0xaf5f87; 0xaf5faf; 0xaf5fd7; 0xaf5fff;
  0xaf8700; 0xaf875f; 0xaf8787; 0xaf87af; 0xaf87d7; 0xaf87ff; 0xafaf00; 0xafaf5f;
  0xafaf87; 0xafafaf; 0xafafd7; 0xafafff; 0xafd700; 0xafd75f; 0xafd787; 0xafd7af;
  0xafd7d7; 0xafd7ff; 0xafff00; 0xafff5f; 0xafff87; 0xafffaf; 0xafffd7; 0xafffff;
  0xd70000; 0xd7005f; 0xd70087; 0xd700af; 0xd700d7; 0xd700ff; 0xd75f00; 0xd75f5f;
  0xd75f87; 0xd75faf; 0xd75fd7; 0xd75fff; 0xd78700; 0xd7875f; 0xd78787; 0xd787af;
  0xd787d7; 0xd787ff; 0xd7af00; 0xd7af5f; 0xd7af87; 0xd7afaf; 0xd7afd7; 0xd7afff;
  0xd7d700; 0xd7d75f; 0xd7d787; 0xd7d7af; 0xd7d7d7; 0xd7d7ff; 0xd7ff00; 0xd7ff5f;
  0xd7ff87; 0xd7ffaf; 0xd7ffd7; 0xd7ffff; 0xff0000; 0xff005f; 0xff0087; 0xff00af;
  0xff00d7; 0xff00ff; 0xff5f00; 0xff5f5f; 0xff5f87; 0xff5faf; 0xff5fd7; 0xff5fff;
  0xff8700; 0xff875f; 0xff8787; 0xff87af; 0xff87d7; 0xff87ff; 0xffaf00; 0xffaf5f;
  0xffaf87; 0xffafaf; 0xffafd7; 0xffafff; 0xffd700; 0xffd75f; 0xffd787; 0xffd7af;
  0xffd7d7; 0xffd7ff; 0xffff00; 0xffff5f; 0xffff87; 0xffffaf; 0xffffd7; 0xffffff;
  0x080808; 0x121212; 0x1c1c1c; 0x262626; 0x303030; 0x3a3a3a; 0x444444; 0x4e4e4e;
  0x585858; 0x626262; 0x6c6c6c; 0x767676; 0x808080; 0x8a8a8a; 0x949494; 0x9e9e9e;
  0xa8a8a8; 0xb2b2b2; 0xbcbcbc; 0xc6c6c6; 0xd0d0d0; 0xdadada; 0xe4e4e4; 0xeeeeee;
]

(* +-----------------------------------------------------------------+
   | Color generation                                                |
   +-----------------------------------------------------------------+ *)

let add_string str strings =
  let rec aux n strings =
    match strings with
      | [] ->
          let id = "data" ^ string_of_int n in
          (id, [(id, str)])
      | (id, str') :: _ when str = str' ->
          (id, strings)
      | x :: strings ->
          let id, strings = aux (n + 1) strings in
          (id, x :: strings)
  in
  aux 0 strings

let code_of_map map strings =
  let index_r, strings = add_string map.index_r strings in
  let index_g, strings = add_string map.index_g strings in
  let index_b, strings = add_string map.index_b strings in
  let mapping, strings = add_string map.map strings in
  let code =
    Printf.sprintf "{
  count_r = %d;
  count_g = %d;
  count_b = %d;
  index_r = %s;
  index_g = %s;
  index_b = %s;
  map = %s;
}"
      map.count_r
      map.count_g
      map.count_b
      index_r
      index_g
      index_b
      mapping
  in
  (code, strings)

let print_string oc str =
  let rec aux i =
    if i = String.length str then
      ()
    else begin
      if i > 0 then output_string oc "\\\n             ";
      let len = min 16 (String.length str - i) in
      for i = i to i + len - 1 do
        Printf.fprintf oc "\\%03u" (Char.code str.[i])
      done;
      aux (i + len)
    end
  in
  aux 0

let () =
  let oc =
    if Array.length Sys.argv < 2 then
      stdout
    else
      open_out Sys.argv.(1)
  in
  let strings = [] in
  let code16, strings = code_of_map colors_16 strings in
  let code88, strings = code_of_map colors_88 strings in
  let code256, strings = code_of_map colors_256 strings in
  output_string oc "(*
 * lTerm_color_mappings.ml
 * -----------------------
 * Copyright : (c) 2012, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

(* This file was generated by gen_color_mappings.ml. *)

";
  List.iter (fun (id, str) -> Printf.fprintf oc "let %s = \"%a\"\n" id print_string str) strings;
  Printf.fprintf oc "
type map = {
  count_r : int;
  count_g : int;
  count_b : int;
  index_r : string;
  index_g : string;
  index_b : string;
  map : string;
}

let colors_16 = %s

let colors_88 = %s

let colors_256 = %s
"
    code16
    code88
    code256
