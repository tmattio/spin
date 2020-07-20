(*
 * zed_edit.ml
 * -----------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Zed, an editor engine.
 *)

open React

(* +-----------------------------------------------------------------+
   | Types                                                           |
   +-----------------------------------------------------------------+ *)

type clipboard = {
  clipboard_get : unit -> Zed_rope.t;
  clipboard_set : Zed_rope.t -> unit;
}

type 'a t = {
  mutable data : 'a option;
  (* Custom data attached to the engine. *)

  mutable text : Zed_rope.t;
  (* The contents of the engine. *)

  mutable lines : Zed_lines.t;
  (* The set of line position of [text]. *)

  changes : Zed_cursor.changes event;
  send_changes : Zed_cursor.changes -> unit;
  (* Changes of the contents. *)

  erase_mode : bool signal;
  set_erase_mode : bool -> unit;
  (* The current erase mode. *)

  editable : int -> int -> bool;
  (* The editable function of the engine. *)

  clipboard : clipboard;
  (* The clipboard for this engine. *)

  mutable mark : Zed_cursor.t;
  (* The cursor that points to the mark. *)

  selection : bool signal;
  set_selection : bool -> unit;
  (* The current selection state. *)

  match_word : Zed_rope.t -> int -> int option;
  (* The function for matching words. *)

  locale : string option signal;
  (* The buffer's locale. *)

  undo : (Zed_rope.t * Zed_lines.t * int * int * int * int * int * int) array;
  (* The undo buffer. It is an array of element of the form [(text,
     lines, pos, new_pos, added, removed, added_width, removed_width)]. *)

  undo_size : int;
  (* Size of the undo buffer. *)

  mutable undo_start : int;
  (* Position of the first used cell in the undo buffer. *)

  mutable undo_index : int;
  (* Position of the next available cell in the undo buffer. *)

  mutable undo_count : int;
  (* Number of used cell in the undo buffer. *)
}

(* +-----------------------------------------------------------------+
   | Creation                                                        |
   +-----------------------------------------------------------------+ *)

let dummy_cursor = Zed_cursor.create 0 E.never (fun () -> Zed_lines.empty) 0 0

let new_clipboard () =
  let r = ref (Zed_rope.empty ()) in
  { clipboard_get = (fun () -> !r);
    clipboard_set = (fun x -> r := x) }

let default_match_word =
  let rec loop_start segmenter zip =
    match Zed_rope.Zip_raw.next zip with
    | exception Zed_rope.Out_of_bounds -> None
    | ch, zip ->
      match Uuseg.add segmenter (`Uchar ch) with
      | `Await          -> loop_start segmenter zip
      | `Uchar _ | `End -> None
      | `Boundary       -> loop_word segmenter zip ~pos:0 `Await
  and loop_word segmenter zip v ~pos =
    match Uuseg.add segmenter v with
    | `Boundary | `End -> Some pos
    | `Uchar _         -> loop_word segmenter zip `Await ~pos:(pos + 1)
    | `Await           ->
      match Zed_rope.Zip_raw.next zip with
      | exception Zed_rope.Out_of_bounds -> Some pos
      | ch, zip -> loop_word segmenter zip (`Uchar ch) ~pos
  in
  fun rope idx ->
    let zip = Zed_rope.Zip_raw.make_f rope idx in
    loop_start (Uuseg.create `Word) zip

let create ?(editable=fun _pos _len -> true) ?(move = (+)) ?clipboard ?(match_word = default_match_word) ?(locale = S.const None) ?(undo_size = 1000) () =
  (* I'm not sure how to disable the unused warning with ocaml.warning and the
     argument can't be removed as it's part of the interface *)
  let _ = move in
  let changes, send_changes = E.create () in
  let erase_mode, set_erase_mode = S.create false in
  let selection, set_selection = S.create false in
  let clipboard =
    match clipboard with
      | Some clipboard ->
          clipboard
      | None ->
          new_clipboard ()
  in
  let edit = {
    data = None;
    text = Zed_rope.empty ();
    lines = Zed_lines.empty;
    changes;
    send_changes;
    erase_mode;
    set_erase_mode;
    editable;
    clipboard;
    mark = dummy_cursor;
    selection;
    set_selection;
    match_word;
    locale;
    undo = Array.make undo_size (Zed_rope.empty (), Zed_lines.empty, 0, 0, 0, 0, 0, 0);
    undo_size;
    undo_start = 0;
    undo_index = 0;
    undo_count = 0;
  } in
  edit.mark <- Zed_cursor.create 0 changes (fun () -> edit.lines) 0 0;
  edit

(* +-----------------------------------------------------------------+
   | State                                                           |
   +-----------------------------------------------------------------+ *)

let get_data engine =
  match engine.data with
    | Some data -> data
    | None -> raise Not_found
let set_data engine data = engine.data <- Some data
let clear_data engine = engine.data <- None
let text engine = engine.text
let lines engine = engine.lines
let changes engine = engine.changes
let erase_mode engine = engine.erase_mode
let get_erase_mode engine = S.value engine.erase_mode
let set_erase_mode engine state = engine.set_erase_mode state
let mark engine = engine.mark
let selection engine = engine.selection
let get_selection engine = S.value engine.selection
let set_selection engine state = engine.set_selection state

let get_line e i =
  let txt = text e in
  let lines = lines e in
  let start = Zed_lines.line_start lines i in
  let stop = Zed_lines.line_stop lines i in
  Zed_rope.sub txt start (stop - start)

let update engine cursors =
  E.select (
    E.stamp engine.changes ()
    :: E.stamp (S.changes engine.selection) ()
    :: E.stamp (S.changes (Zed_cursor.position engine.mark)) ()
    :: List.map (fun cursor -> E.stamp (S.changes (Zed_cursor.position cursor)) ()) cursors
  )

(* +-----------------------------------------------------------------+
   | Cursors                                                         |
   +-----------------------------------------------------------------+ *)

let new_cursor engine =
  Zed_cursor.create (Zed_rope.length engine.text) engine.changes (fun () -> engine.lines) 0 0

(* +-----------------------------------------------------------------+
   | Actions                                                         |
   +-----------------------------------------------------------------+ *)

exception Cannot_edit

type 'a context = {
  edit : 'a t;
  cursor : Zed_cursor.t;
  check : bool;
}

let context ?(check=true) edit cursor =
  { edit; cursor; check }

let edit ctx = ctx.edit
let cursor ctx = ctx.cursor
let check ctx = ctx.check

let with_check check ctx = { ctx with check }

let goto ctx ?set_wanted_column new_position =
  Zed_cursor.goto ctx.cursor ?set_wanted_column new_position

let set_position ctx new_position =
  Zed_cursor.goto ctx.cursor ~set_wanted_column:false new_position

let move ctx ?set_wanted_column delta =
  Zed_cursor.move ctx.cursor ?set_wanted_column delta

let next_line_n ctx n =
  let index = Zed_cursor.get_line ctx.cursor in
  if index + n > Zed_lines.count ctx.edit.lines then
    goto ctx ~set_wanted_column:false (Zed_rope.length ctx.edit.text)
  else begin
    let stop =
      if index + n = Zed_lines.count ctx.edit.lines then
        Zed_rope.length ctx.edit.text
      else
        Zed_lines.line_start ctx.edit.lines (index + n + 1) - 1
    in
    let wanted_idx= Zed_lines.get_idx_by_width
        ctx.edit.lines
        (index + n)
        (Zed_cursor.get_wanted_column ctx.cursor)
    in
    goto ctx ~set_wanted_column:false (min wanted_idx stop)
  end

let prev_line_n ctx n =
  let index = Zed_cursor.get_line ctx.cursor in
  if index - n < 0 then begin
    goto ctx ~set_wanted_column:false 0
  end else begin
    let stop = Zed_lines.line_start ctx.edit.lines (index - (n - 1)) - 1 in
    let wanted_idx= Zed_lines.get_idx_by_width
        ctx.edit.lines
        (index - n)
        (Zed_cursor.get_wanted_column ctx.cursor)
    in
    goto ctx ~set_wanted_column:false (min wanted_idx stop)
  end

let move_line ctx delta =
  match delta with
    | _ when delta < 0 ->
        prev_line_n ctx (-delta)
    | _ when delta > 0 ->
        next_line_n ctx delta
    | _ ->
        ()

let position ctx =
  Zed_cursor.get_position ctx.cursor

let line ctx =
  Zed_cursor.get_line ctx.cursor

let column ctx =
  Zed_cursor.get_column ctx.cursor

let column_display ctx =
  Zed_cursor.get_column_display ctx.cursor

let at_bol ctx =
  Zed_cursor.get_column ctx.cursor = 0

let at_eol ctx =
  let position = Zed_cursor.get_position ctx.cursor in
  let index = Zed_cursor.get_line ctx.cursor in
  if index = Zed_lines.count ctx.edit.lines then
    position = Zed_rope.length ctx.edit.text
  else
    position = Zed_lines.line_start ctx.edit.lines (index + 1) - 1

let at_bot ctx =
  Zed_cursor.get_position ctx.cursor = 0

let at_eot ctx =
  Zed_cursor.get_position ctx.cursor = Zed_rope.length ctx.edit.text

let modify { edit ; _ } text lines position new_position added removed added_width removed_width=
  if edit.undo_size > 0 then begin
    edit.undo.(edit.undo_index) <- (text, lines, position, new_position, added, removed, added_width, removed_width);
    edit.undo_index <- (edit.undo_index + 1) mod edit.undo_size;
    if edit.undo_count = edit.undo_size then
      edit.undo_start <- (edit.undo_start + 1) mod edit.undo_size
    else
      edit.undo_count <- edit.undo_count + 1
  end;
  edit.send_changes {position; added; removed; added_width; removed_width }

let insert ctx rope =
  let position = Zed_cursor.get_position ctx.cursor in
  if not ctx.check || ctx.edit.editable position 0 then begin
    let len = Zed_rope.length rope in
    let text = ctx.edit.text and lines = ctx.edit.lines in
    if S.value ctx.edit.erase_mode then begin
      let text_len = Zed_rope.length ctx.edit.text in
      if position + len > text_len then begin
        let orig_width= Zed_string.(aval_width (width Zed_rope.(to_string (sub text position (text_len-position))))) in
        let curr_width= Zed_string.(aval_width (width Zed_rope.(to_string rope))) in
        ctx.edit.text <- Zed_rope.replace text position (text_len - position) rope;
        ctx.edit.lines <- Zed_lines.replace ctx.edit.lines position (text_len - position) (Zed_lines.of_rope rope);
        modify ctx text lines position position len (text_len - position) curr_width orig_width
      end else begin
        let orig_width= Zed_string.(aval_width (width Zed_rope.(to_string (sub text position len)))) in
        let curr_width= Zed_string.(aval_width (width Zed_rope.(to_string rope))) in
        ctx.edit.text <- Zed_rope.replace text position len rope;
        ctx.edit.lines <- Zed_lines.replace ctx.edit.lines position len (Zed_lines.of_rope rope);
        modify ctx text lines position position len len curr_width orig_width;
      end;
      move ctx len
    end else begin
      let width_add= Zed_string.aval_width (Zed_string.width (Zed_rope.to_string rope)) in
      ctx.edit.text <- Zed_rope.insert ctx.edit.text position rope;
      ctx.edit.lines <- Zed_lines.insert ctx.edit.lines position (Zed_lines.of_rope rope);
      modify ctx text lines position position len 0 width_add 0;
      move ctx len
    end
  end else
    raise Cannot_edit

let insert_char ctx ch =
  if Zed_char.is_combining_mark ch then
    let position = Zed_cursor.get_position ctx.cursor in
    if not ctx.check || ctx.edit.editable position 0 then begin
      let text = ctx.edit.text and lines = ctx.edit.lines in
      try
        ctx.edit.text <- Zed_rope.insert_uChar ctx.edit.text position ch;
        modify ctx text lines position position 1 1 0 0;
        move ctx 0;
        next_line_n ctx 0;
      with _-> ()
    end else
      raise Cannot_edit
  else insert ctx (Zed_rope.of_string (fst (Zed_string.of_uChars [ch])))

let insert_no_erase ctx rope =
  let position = Zed_cursor.get_position ctx.cursor in
  if not ctx.check || ctx.edit.editable position 0 then begin
    let len = Zed_rope.length rope and text = ctx.edit.text and lines = ctx.edit.lines in
    let width_add= Zed_string.aval_width (Zed_string.width (Zed_rope.to_string rope)) in
    ctx.edit.text <- Zed_rope.insert text position rope;
    ctx.edit.lines <- Zed_lines.insert ctx.edit.lines position (Zed_lines.of_rope rope);
    modify ctx text lines position position len 0 width_add 0;
    move ctx len
  end else
    raise Cannot_edit

let remove_next ctx len =
  let position = Zed_cursor.get_position ctx.cursor in
  let text_len = Zed_rope.length ctx.edit.text in
  let len = if position + len > text_len then text_len - position else len in
  if not ctx.check || ctx.edit.editable position len then begin
    let text = ctx.edit.text and lines = ctx.edit.lines in
    let width_remove= Zed_string.(aval_width (width Zed_rope.(to_string (sub text position len)))) in
    ctx.edit.text <- Zed_rope.remove text position len;
    ctx.edit.lines <- Zed_lines.remove ctx.edit.lines position len;
    modify ctx text lines position position 0 len 0 width_remove;
  end else
    raise Cannot_edit

let remove_prev ctx len =
  let position = Zed_cursor.get_position ctx.cursor in
  let len = min position len in
  if not ctx.check || ctx.edit.editable (position - len) len then begin
    let text = ctx.edit.text and lines = ctx.edit.lines in
    let width_remove= Zed_string.(aval_width (width Zed_rope.(to_string (sub text (position-len) len)))) in
    ctx.edit.text <- Zed_rope.remove text (position - len) len;
    ctx.edit.lines <- Zed_lines.remove ctx.edit.lines (position - len) len;
    modify ctx text lines (position - len) position 0 len 0 width_remove;
  end else
    raise Cannot_edit

let remove = remove_next

let replace ctx len rope =
  let position = Zed_cursor.get_position ctx.cursor in
  let text_len = Zed_rope.length ctx.edit.text in
  let len = if position + len > text_len then text_len - position else len in
  if not ctx.check || ctx.edit.editable position len then begin
    let rope_len = Zed_rope.length rope and text = ctx.edit.text and lines = ctx.edit.lines in
    let orig_width= Zed_string.(aval_width (width Zed_rope.(to_string (sub text position len)))) in
    let curr_width= Zed_string.(aval_width (width Zed_rope.(to_string rope))) in
    ctx.edit.text <- Zed_rope.replace text position len rope;
    ctx.edit.lines <- Zed_lines.replace ctx.edit.lines position len (Zed_lines.of_rope rope);
    modify ctx text lines position position rope_len len curr_width orig_width;
    move ctx rope_len
  end else
    raise Cannot_edit

let newline_rope = Zed_rope.singleton
  (Zed_char.unsafe_of_char '\n')

let newline ctx =
  insert ctx newline_rope

let next_char ctx =
  if not (at_eot ctx) then move ctx 1

let prev_char ctx =
  if not (at_bot ctx) then move ctx (-1)

let next_line ctx =
  let index = Zed_cursor.get_line ctx.cursor in
  if index = Zed_lines.count ctx.edit.lines then
    goto ctx ~set_wanted_column:false (Zed_rope.length ctx.edit.text)
  else begin
    let stop =
      if index + 1 = Zed_lines.count ctx.edit.lines then
        Zed_rope.length ctx.edit.text
      else
        Zed_lines.line_start ctx.edit.lines (index + 2) - 1
    in
    let wanted_idx= Zed_lines.get_idx_by_width
        ctx.edit.lines
        (index + 1)
        (Zed_cursor.get_wanted_column ctx.cursor)
    in
    goto ctx ~set_wanted_column:false (min wanted_idx stop)
  end

let prev_line ctx =
  let index = Zed_cursor.get_line ctx.cursor in
  if index = 0 then begin
    goto ctx ~set_wanted_column:false 0
  end else begin
    let stop = Zed_lines.line_start ctx.edit.lines index - 1 in
    let wanted_idx= Zed_lines.get_idx_by_width
        ctx.edit.lines
        (index - 1)
        (Zed_cursor.get_wanted_column ctx.cursor)
    in
    goto ctx ~set_wanted_column:false (min wanted_idx stop)
  end

let join_line ctx =
  let is_space uchar=
    match Uucp.Gc.general_category uchar with
    | `Cc | `Zs | `Zl | `Zp | `Mn -> true
    | _-> false
  in
  let is_not_space uchar= not (is_space uchar) in
  let text = ctx.edit.text in
  let lines= lines ctx.edit in
  let lines_num= Zed_lines.count lines in
  let index = line ctx in
  let position = Zed_lines.line_stop ctx.edit.lines index in
  let len= 1 in
  if index < lines_num then
    if not ctx.check || ctx.edit.editable position len then begin
      let width_remove= 1 in
      if is_not_space (Zed_char.core (Zed_rope.get text (position - 1)))
        && is_not_space (Zed_char.core (Zed_rope.get text (position + 1)))
      then
        let space= Zed_rope.of_string @@ Zed_string.of_utf8 " " in
        let lines_space= Zed_lines.of_rope space in
        ctx.edit.text <- Zed_rope.replace text position len space;
        ctx.edit.lines <- Zed_lines.replace ctx.edit.lines position len lines_space;
        modify ctx text lines position position 0 0 0 0
      else
        (ctx.edit.text <- Zed_rope.remove text position len;
        ctx.edit.lines <- Zed_lines.remove ctx.edit.lines position len;
        modify ctx text lines position position 0 len 0 width_remove)
    end else
      raise Cannot_edit

let goto_bol ctx =
  goto ctx (Zed_lines.line_start ctx.edit.lines (Zed_cursor.get_line ctx.cursor))

let goto_eol ctx =
  let index = Zed_cursor.get_line ctx.cursor in
  if index = Zed_lines.count ctx.edit.lines then
    goto ctx (Zed_rope.length ctx.edit.text)
  else
    goto ctx (Zed_lines.line_start ctx.edit.lines (index + 1) - 1)

let goto_bot ctx =
  goto ctx 0

let goto_eot ctx =
  goto ctx (Zed_rope.length ctx.edit.text)

let delete_next_chars ctx n=
  if not (at_eot ctx) then begin
    ctx.edit.set_selection false;
    remove_next ctx n;
  end

let delete_prev_chars ctx n=
  if not (at_bot ctx) then begin
    ctx.edit.set_selection false;
    remove_prev ctx n;
  end

let kill_next_chars ctx n=
  let position = Zed_cursor.get_position ctx.cursor in
  let end_pos= min (position + n) (Zed_rope.length ctx.edit.text) in
  let n= end_pos - position in
  ctx.edit.clipboard.clipboard_set (Zed_rope.sub ctx.edit.text position n);
  ctx.edit.set_selection false;
  remove ctx n

let kill_prev_chars ctx n=
  let position = Zed_cursor.get_position ctx.cursor in
  let start= max 0 (position - n) in
  let n= position - start in
  ctx.edit.clipboard.clipboard_set (Zed_rope.sub ctx.edit.text start n);
  ctx.edit.set_selection false;
  remove_prev ctx n

let delete_next_char ctx =
  if not (at_eot ctx) then begin
    ctx.edit.set_selection false;
    remove_next ctx 1
  end

let delete_prev_char ctx =
  if not (at_bot ctx) then begin
    ctx.edit.set_selection false;
    remove_prev ctx 1
  end

let delete_next_line ctx =
  ctx.edit.set_selection false;
  let position = Zed_cursor.get_position ctx.cursor in
  let index = Zed_cursor.get_line ctx.cursor in
  if index = Zed_lines.count ctx.edit.lines then
    remove_next ctx (Zed_rope.length ctx.edit.text - position)
  else
    remove_next ctx (Zed_lines.line_start ctx.edit.lines (index + 1) - position)

let delete_prev_line ctx =
  ctx.edit.set_selection false;
  let position = Zed_cursor.get_position ctx.cursor in
  let start = Zed_lines.line_start ctx.edit.lines (Zed_cursor.get_line ctx.cursor) in
  remove_prev ctx (position - start)

let kill_next_line ctx =
  let position = Zed_cursor.get_position ctx.cursor in
  let index = Zed_cursor.get_line ctx.cursor in
  if index = Zed_lines.count ctx.edit.lines then begin
    ctx.edit.clipboard.clipboard_set (Zed_rope.after ctx.edit.text position);
    ctx.edit.set_selection false;
    remove ctx (Zed_rope.length ctx.edit.text - position)
  end else begin
    let len = Zed_lines.line_start ctx.edit.lines (index + 1) - position in
    ctx.edit.clipboard.clipboard_set (Zed_rope.sub ctx.edit.text position len);
    ctx.edit.set_selection false;
    remove ctx len
  end

let kill_prev_line ctx =
  let position = Zed_cursor.get_position ctx.cursor in
  let start = Zed_lines.line_start ctx.edit.lines (Zed_cursor.get_line ctx.cursor) in
  ctx.edit.clipboard.clipboard_set (Zed_rope.sub ctx.edit.text start (position - start));
  ctx.edit.set_selection false;
  remove_prev ctx (position - start)

let switch_erase_mode ctx =
  ctx.edit.set_erase_mode (not (S.value ctx.edit.erase_mode))

let set_mark ctx =
  Zed_cursor.goto ctx.edit.mark (Zed_cursor.get_position ctx.cursor);
  ctx.edit.set_selection true

let goto_mark ctx =
  goto ctx (Zed_cursor.get_position ctx.edit.mark)

let copy ctx =
  if S.value ctx.edit.selection then begin
    let a = Zed_cursor.get_position ctx.cursor and b = Zed_cursor.get_position ctx.edit.mark in
    let a = min a b and b = max a b in
    ctx.edit.clipboard.clipboard_set (Zed_rope.sub ctx.edit.text a (b - a));
    ctx.edit.set_selection false
  end

let copy_sequence ctx start len=
  ctx.edit.clipboard.clipboard_set (Zed_rope.sub ctx.edit.text start len)

let kill ctx =
  if S.value ctx.edit.selection then begin
    let a = Zed_cursor.get_position ctx.cursor and b = Zed_cursor.get_position ctx.edit.mark in
    let a = min a b and b = max a b in
    ctx.edit.clipboard.clipboard_set (Zed_rope.sub ctx.edit.text a (b - a));
    ctx.edit.set_selection false;
    goto ctx a;
    let a = Zed_cursor.get_position ctx.cursor in
    if a <= b then remove ctx (b - a)
  end

let yank ctx =
  ctx.edit.set_selection false;
  insert ctx (ctx.edit.clipboard.clipboard_get ())

let search_word_forward ctx =
  let len = Zed_rope.length ctx.edit.text in
  let rec loop idx =
    if idx = len then
      None
    else
      match ctx.edit.match_word ctx.edit.text idx with
        | Some idx' ->
            Some(idx, idx')
        | None ->
            loop (idx + 1)
  in
  loop (Zed_cursor.get_position ctx.cursor)

let search_word_backward ctx =
  let rec loop idx =
    if idx = -1 then
      None
    else
      match ctx.edit.match_word ctx.edit.text idx with
        | Some idx' ->
            loop2 (idx - 1) (idx, idx')
        | None ->
            loop (idx - 1)
  and loop2 idx result =
    if idx = -1 then
      Some result
    else
      match ctx.edit.match_word ctx.edit.text idx with
        | Some idx' ->
            loop2 (idx - 1) (idx, idx')
        | None ->
            Some result
  in
  loop (Zed_cursor.get_position ctx.cursor - 1)

let capitalize_word ctx =
  match search_word_forward ctx with
    | Some(idx1, idx2) ->
        goto ctx idx1;
        if Zed_cursor.get_position ctx.cursor = idx1 && idx1 < idx2 then begin
          let str = Zed_rope.sub ctx.edit.text idx1 (idx2 - idx1) in
          let ch, str' = Zed_rope.break str 1 in
          replace
            ctx
            (Zed_rope.length str)
            (Zed_rope.append
               (Zed_rope.uppercase ?locale:(S.value ctx.edit.locale) ch)
               (Zed_rope.lowercase ?locale:(S.value ctx.edit.locale) str'))
        end
    | None ->
        ()

let lowercase_word ctx =
  match search_word_forward ctx with
    | Some(idx1, idx2) ->
        goto ctx idx1;
        if Zed_cursor.get_position ctx.cursor = idx1 then begin
          let str = Zed_rope.sub ctx.edit.text idx1 (idx2 - idx1) in
          replace
            ctx
            (Zed_rope.length str)
            (Zed_rope.lowercase ?locale:(S.value ctx.edit.locale) str)
        end
    | None ->
        ()

let uppercase_word ctx =
  match search_word_forward ctx with
    | Some(idx1, idx2) ->
        goto ctx idx1;
        if Zed_cursor.get_position ctx.cursor = idx1 then begin
          let str = Zed_rope.sub ctx.edit.text idx1 (idx2 - idx1) in
          replace
            ctx
            (Zed_rope.length str)
            (Zed_rope.uppercase ?locale:(S.value ctx.edit.locale) str)
        end
    | None ->
        ()

let next_word ctx =
  match search_word_forward ctx with
    | Some(_idx1, idx2) ->
        goto ctx idx2
    | None ->
        goto ctx (Zed_rope.length ctx.edit.text)

let prev_word ctx =
  match search_word_backward ctx with
    | Some(idx1, _idx2) ->
        goto ctx idx1
    | None ->
        goto ctx 0

let delete_next_word ctx =
  let position = Zed_cursor.get_position ctx.cursor in
  let word_end = match search_word_forward ctx with
    | Some(_idx1, idx2) ->
        idx2
    | None ->
      Zed_rope.length ctx.edit.text
  in
  remove ctx (word_end - position)

let delete_prev_word ctx =
  let position = Zed_cursor.get_position ctx.cursor in
  let start = match search_word_backward ctx with
    | Some(idx1, _idx2) ->
        idx1
    | None ->
        0
  in
  remove_prev ctx (position - start)

let kill_next_word ctx =
  let position = Zed_cursor.get_position ctx.cursor in
  let word_end = match search_word_forward ctx with
    | Some(_idx1, idx2) ->
        idx2
    | None ->
      Zed_rope.length ctx.edit.text
  in
  ctx.edit.clipboard.clipboard_set (Zed_rope.sub ctx.edit.text position (word_end - position));
  ctx.edit.set_selection false;
  remove ctx (word_end - position)

let kill_prev_word ctx =
  let position = Zed_cursor.get_position ctx.cursor in
  let start = match search_word_backward ctx with
    | Some(idx1, _idx2) ->
        idx1
    | None ->
        0
  in
  ctx.edit.clipboard.clipboard_set (Zed_rope.sub ctx.edit.text start (position - start));
  ctx.edit.set_selection false;
  remove_prev ctx (position - start)

let undo { check; edit; cursor } =
  if edit.undo_count > 0 then begin
    let index =
      if edit.undo_index = 0 then
        edit.undo_size - 1
      else
        edit.undo_index - 1
    in
    let text, lines, pos, new_pos, added, removed, added_width, removed_width = edit.undo.(index) in
    if not check || edit.editable pos added then begin
      edit.undo_count <- edit.undo_count - 1;
      edit.undo_index <- index;
      edit.text <- text;
      edit.lines <- lines;
      edit.send_changes {position= pos; removed= added; added= removed; added_width= removed_width; removed_width= added_width };
      Zed_cursor.goto cursor new_pos
    end else
      raise Cannot_edit
  end

(* +-----------------------------------------------------------------+
   | Action by names                                                 |
   +-----------------------------------------------------------------+ *)

type action =
  | Insert of Zed_char.t
  | Insert_str of Zed_string.t
  | Newline
  | Next_char
  | Prev_char
  | Next_line
  | Prev_line
  | Join_line
  | Set_pos of int
  | Goto of int
  | Goto_bol
  | Goto_eol
  | Goto_bot
  | Goto_eot
  | Delete_next_chars of int
  | Delete_prev_chars of int
  | Kill_next_chars of int
  | Kill_prev_chars of int
  | Delete_next_char
  | Delete_prev_char
  | Delete_next_line
  | Delete_prev_line
  | Kill_next_line
  | Kill_prev_line
  | Switch_erase_mode
  | Set_mark
  | Goto_mark
  | Copy
  | Kill
  | Yank
  | Capitalize_word
  | Lowercase_word
  | Uppercase_word
  | Next_word
  | Prev_word
  | Delete_next_word
  | Delete_prev_word
  | Kill_next_word
  | Kill_prev_word
  | Undo

let get_action = function
  | Insert ch -> (fun ctx ->
      if Zed_char.length ch = 1
      then insert_char ctx (Zed_char.core ch)
      else insert ctx (Zed_rope.singleton ch))
  | Insert_str str -> (fun ctx ->
      insert ctx (Zed_rope.of_string str))
  | Newline -> newline
  | Next_char -> next_char
  | Prev_char -> prev_char
  | Next_line -> next_line
  | Prev_line -> prev_line
  | Join_line -> join_line
  | Set_pos n -> fun ctx-> set_position ctx n
  | Goto n -> fun ctx-> goto ctx n
  | Goto_bol -> goto_bol
  | Goto_eol -> goto_eol
  | Goto_bot -> goto_bot
  | Goto_eot -> goto_eot
  | Delete_next_chars n-> (fun ctx-> delete_next_chars ctx n)
  | Delete_prev_chars n-> (fun ctx-> delete_prev_chars ctx n)
  | Kill_next_chars n-> (fun ctx-> kill_next_chars ctx n)
  | Kill_prev_chars n-> (fun ctx-> kill_prev_chars ctx n)
  | Delete_next_char -> delete_next_char
  | Delete_prev_char -> delete_prev_char
  | Delete_next_line -> delete_next_line
  | Delete_prev_line -> delete_prev_line
  | Kill_next_line -> kill_next_line
  | Kill_prev_line -> kill_prev_line
  | Switch_erase_mode -> switch_erase_mode
  | Set_mark -> set_mark
  | Goto_mark -> goto_mark
  | Copy -> copy
  | Kill -> kill
  | Yank -> yank
  | Capitalize_word -> capitalize_word
  | Lowercase_word -> lowercase_word
  | Uppercase_word -> uppercase_word
  | Next_word -> next_word
  | Prev_word -> prev_word
  | Delete_next_word -> delete_next_word
  | Delete_prev_word -> delete_prev_word
  | Kill_next_word -> kill_next_word
  | Kill_prev_word -> kill_prev_word
  | Undo -> undo

let doc_of_action = function
  | Insert _ -> "insert the given character."
  | Insert_str _ -> "insert the given string."
  | Newline -> "insert a newline character."
  | Next_char -> "move the cursor to the next character."
  | Prev_char -> "move the cursor to the previous character."
  | Next_line -> "move the cursor to the next line."
  | Prev_line -> "move the cursor to the previous line."
  | Join_line -> "join two lines into one."
  | Set_pos _-> "move the cursor to the position without poking wanted_column"
  | Goto _-> "move the cursor to the position"
  | Goto_bol -> "move the cursor to the beginning of the current line."
  | Goto_eol -> "move the cursor to the end of the current line."
  | Goto_bot -> "move the cursor to the beginning of the text."
  | Goto_eot -> "move the cursor to the end of the text."
  | Delete_next_chars _-> "delete several characters after the cursor."
  | Delete_prev_chars _-> "delete several characters before the cursor."
  | Kill_next_chars _-> "cut several characters after the cursor."
  | Kill_prev_chars _-> "cut several characters before the cursor."
  | Delete_next_char -> "delete the character after the cursor."
  | Delete_prev_char -> "delete the character before the cursor."
  | Delete_next_line -> "delete everything until the end of the current line."
  | Delete_prev_line -> "delete everything until the beginning of the current line."
  | Kill_next_line -> "cut everything until the end of the current line."
  | Kill_prev_line -> "cut everything until the beginning of the current line."
  | Switch_erase_mode -> "switch the current erasing mode."
  | Set_mark -> "set the mark to the current position."
  | Goto_mark -> "move the cursor to the mark."
  | Copy -> "copy the current region to the clipboard."
  | Kill -> "cut the current region to the clipboard."
  | Yank -> "paste the contents of the clipboard at current position."
  | Capitalize_word -> "capitalize the first word after the cursor."
  | Lowercase_word -> "convert the first word after the cursor to lowercase."
  | Uppercase_word -> "convert the first word after the cursor to uppercase."
  | Next_word -> "move the cursor to the end of the next word."
  | Prev_word -> "move the cursor to the beginning of the previous word."
  | Delete_next_word -> "delete up until the next non-word character."
  | Delete_prev_word -> "delete the word behind the cursor."
  | Kill_next_word -> "cut up until the next non-word character."
  | Kill_prev_word -> "cut the word behind the cursor."
  | Undo -> "revert the last action."

let actions = [
  Newline, "newline";
  Next_char, "next-char";
  Prev_char, "prev-char";
  Next_line, "next-line";
  Prev_line, "prev-line";
  Join_line, "join-line";
  Goto_bol, "goto-bol";
  Goto_eol, "goto-eol";
  Goto_bot, "goto-bot";
  Goto_eot, "goto-eot";
  Delete_next_char, "delete-next-char";
  Delete_prev_char, "delete-prev-char";
  Delete_next_line, "delete-next-line";
  Delete_prev_line, "delete-prev-line";
  Kill_next_line, "kill-next-line";
  Kill_prev_line, "kill-prev-line";
  Switch_erase_mode, "switch-erase-mode";
  Set_mark, "set-mark";
  Goto_mark, "goto-mark";
  Copy, "copy";
  Kill, "kill";
  Yank, "yank";
  Capitalize_word, "capitalize-word";
  Lowercase_word, "lowercase-word";
  Uppercase_word, "uppercase-word";
  Next_word, "next-word";
  Prev_word, "prev-word";
  Delete_next_word, "delete-next-word";
  Delete_prev_word, "delete-prev-word";
  Kill_next_word, "kill-next-word";
  Kill_prev_word, "kill-prev-word";
  Undo, "undo";
]

let actions_to_names = Array.of_list (List.sort (fun (a1, _) (a2, _) -> compare a1 a2) actions)
let names_to_actions = Array.of_list (List.sort (fun (_, n1) (_, n2) -> compare n1 n2) actions)

let parse_insert x =
  if Zed_utf8.starts_with x "insert(" && Zed_utf8.ends_with x ")" then begin
    let str = String.sub x 7 (String.length x - 8) in
    if String.length str = 1 && Char.code str.[0] < 128 then
      Insert(Zed_char.unsafe_of_uChar (Uchar.of_char str.[0]))
    else if String.length str > 2 && str.[0] = 'U' && str.[1] = '+' then
      let acc = ref 0 in
      for i = 2 to String.length str - 1 do
        let ch = str.[i] in
        acc := !acc * 16 + (match ch with
                              | '0' .. '9' -> Char.code ch - Char.code '0'
                              | 'a' .. 'f' -> Char.code ch - Char.code 'a' + 10
                              | 'A' .. 'F' -> Char.code ch - Char.code 'A' + 10
                              | _ -> raise Not_found)
      done;
      try
        Insert(Zed_char.unsafe_of_uChar (Uchar.of_int !acc))
      with _ ->
        raise Not_found
    else
      raise Not_found
  end else
    raise Not_found

let parse_insert_str str =
  if Zed_utf8.starts_with str "insert_str(" && Zed_utf8.ends_with str ")" then
    let str = String.sub str 11 (String.length str - 12) in
    try
      Insert_str (Zed_string.of_utf8 str)
    with _ ->
      raise Not_found
  else
    raise Not_found

let parse_action_count action act_name str=
  let act_len= String.length act_name in
  if Zed_utf8.starts_with str (act_name ^ "(") && Zed_utf8.ends_with str ")" then
    let str = String.sub str (act_len+1) (String.length str - (act_len+2)) in
    try
      action (int_of_string str)
    with _ ->
      raise Not_found
  else
    raise Not_found

let parse_set_pos= parse_action_count (fun c-> Set_pos c) "set-pos"

let parse_goto= parse_action_count (fun c-> Goto c) "goto"

let parse_delete_next_chars= parse_action_count
  (fun c-> Delete_next_chars c) "delete-next-chars"

let parse_delete_prev_chars= parse_action_count
  (fun c-> Delete_prev_chars c) "delete-prev-chars"

let parse_kill_next_chars= parse_action_count
  (fun c-> Kill_next_chars c) "kill-next-chars"

let parse_kill_prev_chars= parse_action_count
  (fun c-> Kill_prev_chars c) "kill-prev-chars"

let parse_action_param x=
  try parse_insert x
  with Not_found->
  try parse_insert_str x
  with Not_found->
  try parse_set_pos x
  with Not_found->
  try parse_goto x
  with Not_found->
  try parse_delete_next_chars x
  with Not_found->
  try parse_delete_prev_chars x
  with Not_found->
  try parse_kill_next_chars x
  with Not_found->
  parse_kill_prev_chars x

let action_of_name x =
  let rec loop a b =
    if a = b then
      parse_action_param x
    else
      let c = (a + b) / 2 in
      let action, name = Array.unsafe_get names_to_actions c in
      match compare x name with
        | d when d < 0 ->
            loop a c
        | d when d > 0 ->
            loop (c + 1) b
        | _ ->
            action
  in
  loop 0 (Array.length names_to_actions)

let name_of_action x =
  let rec loop a b =
    if a = b then
      raise Not_found
    else
      let c = (a + b) / 2 in
      let action, name = Array.unsafe_get actions_to_names c in
      match compare x action with
        | d when d < 0 ->
            loop a c
        | d when d > 0 ->
            loop (c + 1) b
        | _ ->
            name
  in
  let open Printf in
  let param_action_to_str name c= sprintf "%s(%d)" name c in
  match x with
    | Insert ch ->
        let code = Uchar.to_int (Zed_char.core ch) in
        if code <= 255 then
          let ch = Char.chr (Uchar.to_int (Zed_char.core ch)) in
          match ch with
            | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' ->
                sprintf "insert(%c)" ch
            | _ ->
                sprintf "insert(U+%02x)" code
        else if code <= 0xffff then
          sprintf "insert(U+%04x)" code
        else
          sprintf "insert(U+%06x)" code
    | Insert_str s->
        sprintf "insert-str(%s)" (Zed_string.to_utf8 s)
    | Set_pos c->
      param_action_to_str "set-pos" c
    | Goto c->
      param_action_to_str "goto" c
    | Delete_next_chars c->
      param_action_to_str "delete-next-chars" c
    | Delete_prev_chars c->
      param_action_to_str "delete-prev-chars" c
    | Kill_next_chars c->
      param_action_to_str "kill-next-chars" c
    | Kill_prev_chars c->
      param_action_to_str "kill-prev-chars" c
    | _ ->
        loop 0 (Array.length actions_to_names)

