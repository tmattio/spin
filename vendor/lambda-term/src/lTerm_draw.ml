(*
 * lTerm_draw.ml
 * -------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Copyright : (c) 2019, ZAN DoYe <zandoye@gmail.com>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

open LTerm_geom
open Result

let unsafe_get matrix line column =
  Array.unsafe_get (Array.unsafe_get matrix line) column

type elem = {
  char : Zed_char.t;
  bold : bool;
  underline : bool;
  blink : bool;
  reverse : bool;
  foreground : LTerm_style.color;
  background : LTerm_style.color;
}

let space = Zed_char.unsafe_of_char ' '
let newline = Zed_char.unsafe_of_char '\n'

let elem_empty=
  { char= space;
    bold= false;
    underline= false;
    blink= false;
    reverse= false;
    foreground= LTerm_style.default;
    background= LTerm_style.default;
  }

type point'=
  | Elem of elem
  | WidthHolder of int

type point= point' ref

type matrix = point array array

let make_matrix size =
  Array.init
    size.rows
    (fun _ ->
       Array.init
         size.cols
         (fun _ -> ref @@ Elem {
            char = Zed_char.unsafe_of_char ' ';
            bold = false;
            underline = false;
            blink = false;
            reverse = false;
            foreground = LTerm_style.default;
            background = LTerm_style.default;
          }))

let set_style_elem elem style=
  let bold=
    match LTerm_style.bold style with
    | Some x-> x
    | None-> elem.bold
  and underline=
    match LTerm_style.underline style with
    | Some x-> x
    | None-> elem.underline
  and blink=
    match LTerm_style.blink style with
    | Some x-> x
    | None-> elem.blink
  and reverse=
    match LTerm_style.reverse style with
    | Some x-> x
    | None-> elem.reverse
  and foreground=
    match LTerm_style.foreground style with
    | Some x-> x
    | None-> elem.foreground
  and background=
    match LTerm_style.background style with
    | Some x-> x
    | None-> elem.background
  in
  { elem with bold; underline; blink; reverse; foreground; background }

let set_style point style=
  match !point with
  | Elem elem-> point:= Elem (set_style_elem elem style)
  | WidthHolder _-> ()

let maybe_set_style point style=
  match !point, style with
  | Elem _, Some style->
    set_style point style
  | _-> ()

type context= {
  ctx_matrix : matrix;
  ctx_matrix_size : size;
  ctx_row1 : int;
  ctx_col1 : int;
  ctx_row2 : int;
  ctx_col2 : int;
}

let context m s =
  if Array.length m <> s.rows then invalid_arg "LTerm_draw.context";
  Array.iter (fun l -> if Array.length l <> s.cols then invalid_arg "LTerm_draw.context") m;
  {
    ctx_matrix = m;
    ctx_matrix_size = s;
    ctx_row1 = 0;
    ctx_col1 = 0;
    ctx_row2 = s.rows;
    ctx_col2 = s.cols;
  }

let size ctx = {
  rows = ctx.ctx_row2 - ctx.ctx_row1;
  cols = ctx.ctx_col2 - ctx.ctx_col1;
}

exception Out_of_bounds

let sub_opt ctx rect =
  if rect.row1 < 0 || rect.col1 < 0 || rect.row1 > rect.row2 || rect.col1 > rect.col2 then None
  else
    let row1 = ctx.ctx_row1 + rect.row1
    and col1 = ctx.ctx_col1 + rect.col1
    and row2 = ctx.ctx_row1 + rect.row2
    and col2 = ctx.ctx_col1 + rect.col2 in
    if row2 > ctx.ctx_row2 || col2 > ctx.ctx_col2 then None
    else Some { ctx with ctx_row1 = row1; ctx_col1 = col1; ctx_row2 = row2; ctx_col2 = col2 }

let sub ctx rect =
  match sub_opt ctx rect with
  | None -> raise Out_of_bounds
  | Some(ctx) -> ctx

let clear ctx =
  for row = ctx.ctx_row1 to ctx.ctx_row2 - 1 do
    for col = ctx.ctx_col1 to ctx.ctx_col2 - 1 do
      let point = unsafe_get ctx.ctx_matrix row col in
      point:= Elem elem_empty
    done
  done

let get_elem matrix row col=
  let point = unsafe_get matrix row col in
  match !point with
  | Elem elem-> elem
  | WidthHolder _-> elem_empty

let fill ctx ?style ch =
  let get_elem= get_elem ctx.ctx_matrix in
  match style with
  | Some style ->
    for row = ctx.ctx_row1 to ctx.ctx_row2 - 1 do
      for col = ctx.ctx_col1 to ctx.ctx_col2 - 1 do
        let point = unsafe_get ctx.ctx_matrix row col in
        let elem=
          match !point with
          | Elem elem-> { elem with char= ch}
          | WidthHolder n->
            let elem= get_elem row (col-n) in
            { elem with char= ch }
        in
        point:= Elem elem;
        set_style point style
      done
    done
  | None ->
    for row = ctx.ctx_row1 to ctx.ctx_row2 - 1 do
      for col = ctx.ctx_col1 to ctx.ctx_col2 - 1 do
        let point = unsafe_get ctx.ctx_matrix row col in
        let elem=
          match !point with
          | Elem elem-> { elem with char= ch}
          | WidthHolder n->
            let elem= get_elem row (col-n) in
            { elem with char= ch }
        in
        point:= Elem elem;
      done
    done

let fill_style ctx style =
  for row = ctx.ctx_row1 to ctx.ctx_row2 - 1 do
    for col = ctx.ctx_col1 to ctx.ctx_col2 - 1 do
      set_style (unsafe_get ctx.ctx_matrix row col) style
    done
  done

let point ctx row col =
  if row < 0 || col < 0 then raise Out_of_bounds;
  let row = ctx.ctx_row1 + row and col = ctx.ctx_col1 + col in
  if row >= ctx.ctx_row2 || col >= ctx.ctx_col2 then raise Out_of_bounds;
  unsafe_get ctx.ctx_matrix row col

let unsafe_del matrix row col len=
  let pos_end= col + len in
  let rec fill elem col n=
    if n > 0 then
      let point= unsafe_get matrix row col in
      point:= Elem elem;
      fill elem (col+1) (n-1)
  in
  let rec find col=
    let point= unsafe_get matrix row col in
    match !point with
    | Elem elem->
      let width= Zed_char.width elem.char in
      let elem= { elem with char= space } in
      point:= Elem elem;
      if width > 1 then
        fill elem (col + 1) (width - 1);
      col + (max width 1)
    | WidthHolder n->
      find (col-n)
  in
  let rec del pos=
    if pos < pos_end then
      del (find col)
  in
  del col

let draw_char_matrix matrix row col ?style ch=
  let size=
    let rows= Array.length matrix in
    let cols=
      if rows > 0 then
        Array.length matrix.(0)
      else 0
    in
    { rows; cols }
  in
  let unsafe_get matrix row col =
    Array.unsafe_get (Array.unsafe_get matrix row) col
  in
  let width= Zed_char.width ch in
  if row >= 0 && col >= 0 && col + width <= size.cols then begin
    let point= unsafe_get matrix row col in
    (match !point with
    | Elem elem-> point:= Elem { elem with char= ch };
      if width > 1 then
        for i = 1 to width - 1 do
          let point= unsafe_get matrix row (col+i) in
          point:= WidthHolder i
        done
    | WidthHolder n->
      unsafe_del matrix row (col-n) 1;
      let elem= get_elem matrix row (col-n) in
      point:= Elem { elem with char= ch };
      if width > 1 then
        for i = 1 to width - 1 do
          let point= unsafe_get matrix row (col+i) in
          point:= WidthHolder i
        done
      );
    maybe_set_style point style
  end

let unsafe_draw_char_raw ctx row col ?style ch=
  let width= Zed_char.width ch in
  if row >= 0 && col >= 0 then begin
    let point= unsafe_get ctx.ctx_matrix row col in
    (match !point with
    | Elem elem-> point:= Elem { elem with char= ch };
      if width > 1 then
        for i = 1 to width - 1 do
          let point= unsafe_get ctx.ctx_matrix row (col+i) in
          point:= WidthHolder i
        done
    | WidthHolder n->
      unsafe_del ctx.ctx_matrix row (col-n) 1;
      let elem= get_elem ctx.ctx_matrix row (col-n) in
      point:= Elem { elem with char= ch };
      if width > 1 then
        for i = 1 to width - 1 do
          let point= unsafe_get ctx.ctx_matrix row (col+i) in
          point:= WidthHolder i
        done
      );
    maybe_set_style point style
  end

let draw_char_raw ctx row col ?style ch=
  let width= Zed_char.width ch in
  if row >= ctx.ctx_row1 && row < ctx.ctx_row2 && col >= ctx.ctx_col1 && col + width <= ctx.ctx_col2 then
    unsafe_draw_char_raw ctx row col ?style ch

let draw_char ctx row col ?style ch=
  let row= ctx.ctx_row1 + row
  and col = ctx.ctx_col1 + col in
  draw_char_raw ctx row col ?style ch

let draw_string ctx row col ?style str=
  let len= Zed_string.bytes str in
  let rec loop row col ofs=
    if ofs < len then
      let ch, ofs= Zed_string.extract_next str ofs in
      if ch = newline then
        loop (row + 1) ctx.ctx_col1 ofs
      else begin
        let width= Zed_char.width ch in
        draw_char_raw ctx row col ?style ch;
        loop row (col + max 0 width) ofs
      end
  in
  loop (ctx.ctx_row1 + row) (ctx.ctx_col1 + col) 0

let draw_styled ctx row col ?style str=
  let rec loop row col idx=
    if idx < Array.length str then begin
      let ch, ch_style= Array.unsafe_get str idx in
      if ch = newline then
        loop (row + 1) ctx.ctx_col1 (idx + 1)
      else begin
        let width= Zed_char.width ch in
        if row >= ctx.ctx_row1 && row < ctx.ctx_row2 && col >= ctx.ctx_col1 && col + width <= ctx.ctx_col2 then begin
          let point= unsafe_get ctx.ctx_matrix row col in
          draw_char_raw ctx row col ?style ch;
          set_style point ch_style;
        end;
        loop row (col + max 0 width) (idx + 1);
      end
    end
  in
  loop (ctx.ctx_row1 + row) (ctx.ctx_col1 + col) 0

let draw_string_aligned ctx row alignment ?style str=
  let actual_width=
    function
    | Ok {Zed_string.len=_;width}-> width
    | Error {Zed_string.start=_;len=_;width}-> width
  in
  let line_width start= actual_width (Zed_string.width_ofs ~start str) in
  let rec loop row col ofs=
    if ofs < Zed_string.bytes str then begin
      let ch, ofs= Zed_string.extract_next str ofs in
      if ch = newline then
        ofs
      else begin
        let width= Zed_char.width ch in
        draw_char_raw ctx row col ?style ch;
        loop row (col + max 0 width) ofs;
      end
    end else
      ofs
  in
  let rec loop_lines row ofs=
    if ofs < Zed_string.bytes str then begin
      let ofs=
        loop row
          (match alignment with
          | H_align_left ->
            ctx.ctx_col1
          | H_align_center ->
            ctx.ctx_col1 + (ctx.ctx_col2 - ctx.ctx_col1 - line_width ofs) / 2
          | H_align_right ->
            ctx.ctx_col2 - line_width ofs)
          ofs
      in
      loop_lines (row + 1) ofs
    end
  in
  loop_lines (ctx.ctx_row1 + row) 0

let draw_styled_aligned ctx row alignment ?style str=
  let str, styles=
    let len= Array.length str in
    Zed_string.implode (Array.to_list (Array.init len (fun i-> fst (Array.get str i))))
    , (Array.init len (fun i-> snd (Array.get str i)))
  in
  let actual_width= function
    | Ok {Zed_string.len=_;width}-> width
    | Error {Zed_string.start=_;len=_;width}-> width
  in
  let line_width start= actual_width (Zed_string.width_ofs ~start str) in
  let rec loop row col idx ofs=
    if ofs < Zed_string.bytes str then begin
      let (ch, ofs), ch_style=
        Zed_string.extract_next str ofs, Array.unsafe_get styles idx
      and idx= idx + 1 in
      if ch = newline then
        (idx, ofs)
      else begin
        let point= unsafe_get ctx.ctx_matrix row col in
        draw_char_raw ctx row col ?style ch;
        set_style point ch_style;
        loop row (col + Zed_char.width ch) idx ofs;
      end
    end else
      (idx, ofs)
  in
  let rec loop_lines row idx ofs=
    if ofs < Zed_string.bytes str then begin
      let idx, ofs=
        loop row
          (match alignment with
          | H_align_left ->
            ctx.ctx_col1
          | H_align_center ->
            ctx.ctx_col1 + (ctx.ctx_col2 - ctx.ctx_col1 - line_width ofs) / 2
          | H_align_right ->
            ctx.ctx_col2 - line_width idx)
          idx
          ofs
      in
      loop_lines (row + 1) idx ofs
    end
  in
  loop_lines (ctx.ctx_row1 + row) 0 0

type connection =
  | Blank
  | Light
  | Heavy

type piece = { top : connection; bottom : connection; left : connection; right : connection }

let piece_of_char char =
  match Uchar.to_int char with
    | 0x2500 -> Some { top = Blank; bottom = Blank; left = Light; right = Light }
    | 0x2501 -> Some { top = Blank; bottom = Blank; left = Heavy; right = Heavy }
    | 0x2502 -> Some { top = Light; bottom = Light; left = Blank; right = Blank }
    | 0x2503 -> Some { top = Heavy; bottom = Heavy; left = Blank; right = Blank }
    | 0x250c -> Some { top = Blank; bottom = Light; left = Blank; right = Light }
    | 0x250d -> Some { top = Blank; bottom = Light; left = Blank; right = Heavy }
    | 0x250e -> Some { top = Blank; bottom = Heavy; left = Blank; right = Light }
    | 0x250f -> Some { top = Blank; bottom = Heavy; left = Blank; right = Heavy }
    | 0x2510 -> Some { top = Blank; bottom = Light; left = Light; right = Blank }
    | 0x2511 -> Some { top = Blank; bottom = Light; left = Heavy; right = Blank }
    | 0x2512 -> Some { top = Blank; bottom = Heavy; left = Light; right = Blank }
    | 0x2513 -> Some { top = Blank; bottom = Heavy; left = Heavy; right = Blank }
    | 0x2514 -> Some { top = Light; bottom = Blank; left = Blank; right = Light }
    | 0x2515 -> Some { top = Light; bottom = Blank; left = Blank; right = Heavy }
    | 0x2516 -> Some { top = Heavy; bottom = Blank; left = Blank; right = Light }
    | 0x2517 -> Some { top = Heavy; bottom = Blank; left = Blank; right = Heavy }
    | 0x2518 -> Some { top = Light; bottom = Blank; left = Light; right = Blank }
    | 0x2519 -> Some { top = Light; bottom = Blank; left = Heavy; right = Blank }
    | 0x251a -> Some { top = Heavy; bottom = Blank; left = Light; right = Blank }
    | 0x251b -> Some { top = Heavy; bottom = Blank; left = Heavy; right = Blank }
    | 0x251c -> Some { top = Light; bottom = Light; left = Blank; right = Light }
    | 0x251d -> Some { top = Light; bottom = Light; left = Blank; right = Heavy }
    | 0x251e -> Some { top = Heavy; bottom = Light; left = Blank; right = Light }
    | 0x251f -> Some { top = Light; bottom = Heavy; left = Blank; right = Light }
    | 0x2520 -> Some { top = Heavy; bottom = Heavy; left = Blank; right = Light }
    | 0x2521 -> Some { top = Heavy; bottom = Light; left = Blank; right = Heavy }
    | 0x2522 -> Some { top = Light; bottom = Heavy; left = Blank; right = Heavy }
    | 0x2523 -> Some { top = Heavy; bottom = Heavy; left = Blank; right = Heavy }
    | 0x2524 -> Some { top = Light; bottom = Light; left = Light; right = Blank }
    | 0x2525 -> Some { top = Light; bottom = Light; left = Heavy; right = Blank }
    | 0x2526 -> Some { top = Heavy; bottom = Light; left = Light; right = Blank }
    | 0x2527 -> Some { top = Light; bottom = Heavy; left = Light; right = Blank }
    | 0x2528 -> Some { top = Heavy; bottom = Heavy; left = Light; right = Blank }
    | 0x2529 -> Some { top = Heavy; bottom = Light; left = Heavy; right = Blank }
    | 0x252a -> Some { top = Light; bottom = Heavy; left = Heavy; right = Blank }
    | 0x252b -> Some { top = Heavy; bottom = Heavy; left = Heavy; right = Blank }
    | 0x252c -> Some { top = Blank; bottom = Light; left = Light; right = Light }
    | 0x252d -> Some { top = Blank; bottom = Light; left = Heavy; right = Light }
    | 0x252e -> Some { top = Blank; bottom = Light; left = Light; right = Heavy }
    | 0x252f -> Some { top = Blank; bottom = Light; left = Heavy; right = Heavy }
    | 0x2530 -> Some { top = Blank; bottom = Heavy; left = Light; right = Light }
    | 0x2531 -> Some { top = Blank; bottom = Heavy; left = Heavy; right = Light }
    | 0x2532 -> Some { top = Blank; bottom = Heavy; left = Light; right = Heavy }
    | 0x2533 -> Some { top = Blank; bottom = Heavy; left = Heavy; right = Heavy }
    | 0x2534 -> Some { top = Light; bottom = Blank; left = Light; right = Light }
    | 0x2535 -> Some { top = Light; bottom = Blank; left = Heavy; right = Light }
    | 0x2536 -> Some { top = Light; bottom = Blank; left = Light; right = Heavy }
    | 0x2537 -> Some { top = Light; bottom = Blank; left = Heavy; right = Heavy }
    | 0x2538 -> Some { top = Heavy; bottom = Blank; left = Light; right = Light }
    | 0x2539 -> Some { top = Heavy; bottom = Blank; left = Heavy; right = Light }
    | 0x253a -> Some { top = Heavy; bottom = Blank; left = Light; right = Heavy }
    | 0x253b -> Some { top = Heavy; bottom = Blank; left = Heavy; right = Heavy }
    | 0x253c -> Some { top = Light; bottom = Light; left = Light; right = Light }
    | 0x253d -> Some { top = Light; bottom = Light; left = Heavy; right = Light }
    | 0x253e -> Some { top = Light; bottom = Light; left = Light; right = Heavy }
    | 0x253f -> Some { top = Light; bottom = Light; left = Heavy; right = Heavy }
    | 0x2540 -> Some { top = Heavy; bottom = Light; left = Light; right = Light }
    | 0x2541 -> Some { top = Light; bottom = Heavy; left = Light; right = Light }
    | 0x2542 -> Some { top = Heavy; bottom = Heavy; left = Light; right = Light }
    | 0x2543 -> Some { top = Heavy; bottom = Light; left = Heavy; right = Light }
    | 0x2544 -> Some { top = Heavy; bottom = Light; left = Light; right = Heavy }
    | 0x2545 -> Some { top = Light; bottom = Heavy; left = Heavy; right = Light }
    | 0x2546 -> Some { top = Light; bottom = Heavy; left = Light; right = Heavy }
    | 0x2547 -> Some { top = Heavy; bottom = Light; left = Heavy; right = Heavy }
    | 0x2548 -> Some { top = Light; bottom = Heavy; left = Heavy; right = Heavy }
    | 0x2549 -> Some { top = Heavy; bottom = Heavy; left = Heavy; right = Light }
    | 0x254a -> Some { top = Heavy; bottom = Heavy; left = Light; right = Heavy }
    | 0x254b -> Some { top = Heavy; bottom = Heavy; left = Heavy; right = Heavy }
    | 0x2574 -> Some { top = Blank; bottom = Blank; left = Light; right = Blank }
    | 0x2575 -> Some { top = Light; bottom = Blank; left = Blank; right = Blank }
    | 0x2576 -> Some { top = Blank; bottom = Blank; left = Blank; right = Light }
    | 0x2577 -> Some { top = Blank; bottom = Light; left = Blank; right = Blank }
    | 0x2578 -> Some { top = Blank; bottom = Blank; left = Heavy; right = Blank }
    | 0x2579 -> Some { top = Heavy; bottom = Blank; left = Blank; right = Blank }
    | 0x257a -> Some { top = Blank; bottom = Blank; left = Blank; right = Heavy }
    | 0x257b -> Some { top = Blank; bottom = Heavy; left = Blank; right = Blank }
    | 0x257c -> Some { top = Blank; bottom = Blank; left = Light; right = Heavy }
    | 0x257d -> Some { top = Light; bottom = Heavy; left = Blank; right = Blank }
    | 0x257e -> Some { top = Blank; bottom = Blank; left = Heavy; right = Light }
    | 0x257f -> Some { top = Heavy; bottom = Light; left = Blank; right = Blank }
    | _ -> None

let char_of_piece = function
  | { top = Blank; bottom = Blank; left = Blank; right = Blank } -> Uchar.of_int 0x0020
  | { top = Blank; bottom = Blank; left = Light; right = Light } -> Uchar.of_int 0x2500
  | { top = Blank; bottom = Blank; left = Heavy; right = Heavy } -> Uchar.of_int 0x2501
  | { top = Light; bottom = Light; left = Blank; right = Blank } -> Uchar.of_int 0x2502
  | { top = Heavy; bottom = Heavy; left = Blank; right = Blank } -> Uchar.of_int 0x2503
  | { top = Blank; bottom = Light; left = Blank; right = Light } -> Uchar.of_int 0x250c
  | { top = Blank; bottom = Light; left = Blank; right = Heavy } -> Uchar.of_int 0x250d
  | { top = Blank; bottom = Heavy; left = Blank; right = Light } -> Uchar.of_int 0x250e
  | { top = Blank; bottom = Heavy; left = Blank; right = Heavy } -> Uchar.of_int 0x250f
  | { top = Blank; bottom = Light; left = Light; right = Blank } -> Uchar.of_int 0x2510
  | { top = Blank; bottom = Light; left = Heavy; right = Blank } -> Uchar.of_int 0x2511
  | { top = Blank; bottom = Heavy; left = Light; right = Blank } -> Uchar.of_int 0x2512
  | { top = Blank; bottom = Heavy; left = Heavy; right = Blank } -> Uchar.of_int 0x2513
  | { top = Light; bottom = Blank; left = Blank; right = Light } -> Uchar.of_int 0x2514
  | { top = Light; bottom = Blank; left = Blank; right = Heavy } -> Uchar.of_int 0x2515
  | { top = Heavy; bottom = Blank; left = Blank; right = Light } -> Uchar.of_int 0x2516
  | { top = Heavy; bottom = Blank; left = Blank; right = Heavy } -> Uchar.of_int 0x2517
  | { top = Light; bottom = Blank; left = Light; right = Blank } -> Uchar.of_int 0x2518
  | { top = Light; bottom = Blank; left = Heavy; right = Blank } -> Uchar.of_int 0x2519
  | { top = Heavy; bottom = Blank; left = Light; right = Blank } -> Uchar.of_int 0x251a
  | { top = Heavy; bottom = Blank; left = Heavy; right = Blank } -> Uchar.of_int 0x251b
  | { top = Light; bottom = Light; left = Blank; right = Light } -> Uchar.of_int 0x251c
  | { top = Light; bottom = Light; left = Blank; right = Heavy } -> Uchar.of_int 0x251d
  | { top = Heavy; bottom = Light; left = Blank; right = Light } -> Uchar.of_int 0x251e
  | { top = Light; bottom = Heavy; left = Blank; right = Light } -> Uchar.of_int 0x251f
  | { top = Heavy; bottom = Heavy; left = Blank; right = Light } -> Uchar.of_int 0x2520
  | { top = Heavy; bottom = Light; left = Blank; right = Heavy } -> Uchar.of_int 0x2521
  | { top = Light; bottom = Heavy; left = Blank; right = Heavy } -> Uchar.of_int 0x2522
  | { top = Heavy; bottom = Heavy; left = Blank; right = Heavy } -> Uchar.of_int 0x2523
  | { top = Light; bottom = Light; left = Light; right = Blank } -> Uchar.of_int 0x2524
  | { top = Light; bottom = Light; left = Heavy; right = Blank } -> Uchar.of_int 0x2525
  | { top = Heavy; bottom = Light; left = Light; right = Blank } -> Uchar.of_int 0x2526
  | { top = Light; bottom = Heavy; left = Light; right = Blank } -> Uchar.of_int 0x2527
  | { top = Heavy; bottom = Heavy; left = Light; right = Blank } -> Uchar.of_int 0x2528
  | { top = Heavy; bottom = Light; left = Heavy; right = Blank } -> Uchar.of_int 0x2529
  | { top = Light; bottom = Heavy; left = Heavy; right = Blank } -> Uchar.of_int 0x252a
  | { top = Heavy; bottom = Heavy; left = Heavy; right = Blank } -> Uchar.of_int 0x252b
  | { top = Blank; bottom = Light; left = Light; right = Light } -> Uchar.of_int 0x252c
  | { top = Blank; bottom = Light; left = Heavy; right = Light } -> Uchar.of_int 0x252d
  | { top = Blank; bottom = Light; left = Light; right = Heavy } -> Uchar.of_int 0x252e
  | { top = Blank; bottom = Light; left = Heavy; right = Heavy } -> Uchar.of_int 0x252f
  | { top = Blank; bottom = Heavy; left = Light; right = Light } -> Uchar.of_int 0x2530
  | { top = Blank; bottom = Heavy; left = Heavy; right = Light } -> Uchar.of_int 0x2531
  | { top = Blank; bottom = Heavy; left = Light; right = Heavy } -> Uchar.of_int 0x2532
  | { top = Blank; bottom = Heavy; left = Heavy; right = Heavy } -> Uchar.of_int 0x2533
  | { top = Light; bottom = Blank; left = Light; right = Light } -> Uchar.of_int 0x2534
  | { top = Light; bottom = Blank; left = Heavy; right = Light } -> Uchar.of_int 0x2535
  | { top = Light; bottom = Blank; left = Light; right = Heavy } -> Uchar.of_int 0x2536
  | { top = Light; bottom = Blank; left = Heavy; right = Heavy } -> Uchar.of_int 0x2537
  | { top = Heavy; bottom = Blank; left = Light; right = Light } -> Uchar.of_int 0x2538
  | { top = Heavy; bottom = Blank; left = Heavy; right = Light } -> Uchar.of_int 0x2539
  | { top = Heavy; bottom = Blank; left = Light; right = Heavy } -> Uchar.of_int 0x253a
  | { top = Heavy; bottom = Blank; left = Heavy; right = Heavy } -> Uchar.of_int 0x253b
  | { top = Light; bottom = Light; left = Light; right = Light } -> Uchar.of_int 0x253c
  | { top = Light; bottom = Light; left = Heavy; right = Light } -> Uchar.of_int 0x253d
  | { top = Light; bottom = Light; left = Light; right = Heavy } -> Uchar.of_int 0x253e
  | { top = Light; bottom = Light; left = Heavy; right = Heavy } -> Uchar.of_int 0x253f
  | { top = Heavy; bottom = Light; left = Light; right = Light } -> Uchar.of_int 0x2540
  | { top = Light; bottom = Heavy; left = Light; right = Light } -> Uchar.of_int 0x2541
  | { top = Heavy; bottom = Heavy; left = Light; right = Light } -> Uchar.of_int 0x2542
  | { top = Heavy; bottom = Light; left = Heavy; right = Light } -> Uchar.of_int 0x2543
  | { top = Heavy; bottom = Light; left = Light; right = Heavy } -> Uchar.of_int 0x2544
  | { top = Light; bottom = Heavy; left = Heavy; right = Light } -> Uchar.of_int 0x2545
  | { top = Light; bottom = Heavy; left = Light; right = Heavy } -> Uchar.of_int 0x2546
  | { top = Heavy; bottom = Light; left = Heavy; right = Heavy } -> Uchar.of_int 0x2547
  | { top = Light; bottom = Heavy; left = Heavy; right = Heavy } -> Uchar.of_int 0x2548
  | { top = Heavy; bottom = Heavy; left = Heavy; right = Light } -> Uchar.of_int 0x2549
  | { top = Heavy; bottom = Heavy; left = Light; right = Heavy } -> Uchar.of_int 0x254a
  | { top = Heavy; bottom = Heavy; left = Heavy; right = Heavy } -> Uchar.of_int 0x254b
  | { top = Blank; bottom = Blank; left = Light; right = Blank } -> Uchar.of_int 0x2574
  | { top = Light; bottom = Blank; left = Blank; right = Blank } -> Uchar.of_int 0x2575
  | { top = Blank; bottom = Blank; left = Blank; right = Light } -> Uchar.of_int 0x2576
  | { top = Blank; bottom = Light; left = Blank; right = Blank } -> Uchar.of_int 0x2577
  | { top = Blank; bottom = Blank; left = Heavy; right = Blank } -> Uchar.of_int 0x2578
  | { top = Heavy; bottom = Blank; left = Blank; right = Blank } -> Uchar.of_int 0x2579
  | { top = Blank; bottom = Blank; left = Blank; right = Heavy } -> Uchar.of_int 0x257a
  | { top = Blank; bottom = Heavy; left = Blank; right = Blank } -> Uchar.of_int 0x257b
  | { top = Blank; bottom = Blank; left = Light; right = Heavy } -> Uchar.of_int 0x257c
  | { top = Light; bottom = Heavy; left = Blank; right = Blank } -> Uchar.of_int 0x257d
  | { top = Blank; bottom = Blank; left = Heavy; right = Light } -> Uchar.of_int 0x257e
  | { top = Heavy; bottom = Light; left = Blank; right = Blank } -> Uchar.of_int 0x257f

let piece_of_point point=
  match !point with
  | Elem elem-> piece_of_char (Zed_char.core elem.char)
  | WidthHolder _-> None

let draw_piece ctx row col ?style piece=
  let row= ctx.ctx_row1 + row and col= ctx.ctx_col1 + col in
  if row >= ctx.ctx_row1 && col >= ctx.ctx_col1 && row < ctx.ctx_row2 && col < ctx.ctx_col2 then begin
    let piece=
      if row > 0 then begin
        let point= unsafe_get ctx.ctx_matrix (row - 1) col in
        match piece_of_point point with
        | None ->
          piece
        | Some piece' ->
          if piece.top = piece'.bottom then
            piece
          else if piece.top = Blank then
            { piece with top = piece'.bottom }
          else if piece'.bottom = Blank then begin
            let char= Zed_char.unsafe_of_uChar
              (char_of_piece { piece' with bottom = piece.top })
            in
            unsafe_draw_char_raw ctx (row-1) col char;
            piece
          end else
            piece
      end else
        piece
    in
    let piece=
      if row < ctx.ctx_matrix_size.rows - 1 then begin
        let point= unsafe_get ctx.ctx_matrix (row + 1) col in
        match piece_of_point point with
        | None ->
          piece
        | Some piece' ->
          if piece.bottom = piece'.top then
            piece
          else if piece.bottom = Blank then
            { piece with bottom = piece'.top }
          else if piece'.top = Blank then begin
            let char= Zed_char.unsafe_of_uChar
              (char_of_piece { piece' with top = piece.bottom })
            in
            unsafe_draw_char_raw ctx (row+1) col char;
            piece
          end else
            piece
      end else
        piece
    in
    let piece=
      if col > 0 then begin
        let point= unsafe_get ctx.ctx_matrix row (col - 1) in
        match piece_of_point point with
        | None ->
          piece
        | Some piece' ->
          if piece.left = piece'.right then
            piece
          else if piece.left = Blank then
            { piece with left = piece'.right }
          else if piece'.right = Blank then begin
            let char= Zed_char.unsafe_of_uChar
              (char_of_piece { piece' with right = piece.left })
            in
            unsafe_draw_char_raw ctx row (col-1) char;
            piece
          end else
            piece
      end else
        piece
    in
    let piece=
      if col < ctx.ctx_matrix_size.cols - 1 then begin
        let point= unsafe_get ctx.ctx_matrix row (col + 1) in
        match piece_of_point point with
        | None ->
          piece
        | Some piece' ->
          if piece.right = piece'.left then
            piece
          else if piece.right = Blank then
            { piece with right = piece'.left }
          else if piece'.left = Blank then begin
            let char= Zed_char.unsafe_of_uChar
              (char_of_piece { piece' with left = piece.right })
            in
            unsafe_draw_char_raw ctx row (col+1) char;
            piece
          end else
            piece
      end else
        piece
    in
    let char= Zed_char.unsafe_of_uChar (char_of_piece piece) in
    unsafe_draw_char_raw ctx row col ?style char
  end

let draw_hline ctx row col len ?style connection =
  let piece = { top = Blank; bottom = Blank; left = connection; right = connection } in
  for i = 0 to len - 1 do
    draw_piece ctx row (col + i) ?style piece
  done

let draw_vline ctx row col len ?style connection =
  let piece = { top = connection; bottom = connection; left = Blank; right = Blank } in
  for i = 0 to len - 1 do
    draw_piece ctx (row + i) col ?style piece
  done

let draw_frame ctx rect ?style connection =
  let hline = { top = Blank; bottom = Blank; left = connection; right = connection } in
  let vline = { top = connection; bottom = connection; left = Blank; right = Blank } in
  for col = rect.col1 + 1 to rect.col2 - 2 do
    draw_piece ctx (rect.row1 + 0) col ?style hline;
    draw_piece ctx (rect.row2 - 1) col ?style hline
  done;
  for row = rect.row1 + 1 to rect.row2 - 2 do
    draw_piece ctx row (rect.col1 + 0) ?style vline;
    draw_piece ctx row (rect.col2 - 1) ?style vline
  done;
  draw_piece ctx (rect.row1 + 0) (rect.col1 + 0) ?style { top = Blank; bottom = connection; left = Blank; right = connection };
  draw_piece ctx (rect.row1 + 0) (rect.col2 - 1) ?style { top = Blank; bottom = connection; left = connection; right = Blank };
  draw_piece ctx (rect.row2 - 1) (rect.col2 - 1) ?style { top = connection; bottom = Blank; left = connection; right = Blank };
  draw_piece ctx (rect.row2 - 1) (rect.col1 + 0) ?style { top = connection; bottom = Blank; left = Blank; right = connection }

let draw_frame_labelled ctx rect ?style ?(alignment=H_align_left) label connection =
  draw_frame ctx rect ?style connection;
  let rect = { row1 = rect.row1; row2 = rect.row1+1; col1 = rect.col1+1; col2 = rect.col2-1 } in
  match sub_opt ctx rect with
  | Some(ctx) -> draw_string_aligned ctx 0 alignment label
  | None -> ()
