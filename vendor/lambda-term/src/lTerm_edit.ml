(*
 * lTerm_edit.ml
 * -------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

let pervasives_compare= compare

open Zed_edit
open LTerm_key
open LTerm_geom
open Lwt_react

(* +-----------------------------------------------------------------+
   | Actions                                                         |
   +-----------------------------------------------------------------+ *)

type action =
  | Zed of Zed_edit.action
  | Start_macro
  | Stop_macro
  | Cancel_macro
  | Play_macro
  | Insert_macro_counter
  | Set_macro_counter
  | Add_macro_counter
  | Custom of (unit -> unit)

let doc_of_action = function
  | Zed action -> Zed_edit.doc_of_action action
  | Start_macro -> "start a new macro."
  | Stop_macro -> "end the current macro."
  | Cancel_macro -> "cancel the current macro."
  | Play_macro -> "play the last recorded macro."
  | Insert_macro_counter -> "insert the current value of the macro counter."
  | Set_macro_counter -> "sets the value of the macro counter."
  | Add_macro_counter -> "adds a value to the macro counter."
  | Custom _ -> "programmer defined action."

let actions = [
  Start_macro, "start-macro";
  Stop_macro, "stop-macro";
  Cancel_macro, "cancel-macro";
  Play_macro, "play-macro";
  Insert_macro_counter, "insert-macro-counter";
  Set_macro_counter, "set-macro-counter";
  Add_macro_counter, "add-macro-counter";
]

let actions_to_names = Array.of_list (List.sort (fun (a1, _) (a2, _) -> pervasives_compare a1 a2) actions)
let names_to_actions = Array.of_list (List.sort (fun (_, n1) (_, n2) -> pervasives_compare n1 n2) actions)

let action_of_name x =
  let rec loop a b =
    if a = b then
      Zed (Zed_edit.action_of_name x)
    else
      let c = (a + b) / 2 in
      let action, name = Array.unsafe_get names_to_actions c in
      match pervasives_compare x name with
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
      match pervasives_compare x action with
        | d when d < 0 ->
            loop a c
        | d when d > 0 ->
            loop (c + 1) b
        | _ ->
            name
  in
  match x with
    | Zed x -> Zed_edit.name_of_action x
    | Custom _ -> "custom"
    | _ -> loop 0 (Array.length actions_to_names)

module Bindings = Zed_input.Make (LTerm_key)

let bindings = ref Bindings.empty

let bind seq actions = bindings := Bindings.add seq actions !bindings
let unbind seq = bindings := Bindings.remove seq !bindings

let () =
  bind [{ control = false; meta = false; shift = false; code = Left }] [Zed Prev_char];
  bind [{ control = false; meta = false; shift = false; code = Right }] [Zed Next_char];
  bind [{ control = false; meta = false; shift = false; code = Up }] [Zed Prev_line];
  bind [{ control = false; meta = false; shift = false; code = Down }] [Zed Next_line];
  bind [{ control = false; meta = false; shift = false; code = Home }] [Zed Goto_bol];
  bind [{ control = false; meta = false; shift = false; code = End }] [Zed Goto_eol];
  bind [{ control = false; meta = false; shift = false; code = Insert }] [Zed Switch_erase_mode];
  bind [{ control = false; meta = false; shift = false; code = Delete }] [Zed Delete_next_char];
  bind [{ control = false; meta = false; shift = false; code = Enter }] [Zed Newline];
  bind [{ control = true; meta = false; shift = false; code = Char(Uchar.of_char ' ') }] [Zed Set_mark];
  bind [{ control = true; meta = false; shift = false; code = Char(Uchar.of_char 'a') }] [Zed Goto_bol];
  bind [{ control = true; meta = false; shift = false; code = Char(Uchar.of_char 'e') }] [Zed Goto_eol];
  bind [{ control = true; meta = false; shift = false; code = Char(Uchar.of_char 'd') }] [Zed Delete_next_char];
  bind [{ control = true; meta = false; shift = false; code = Char(Uchar.of_char 'h') }] [Zed Delete_prev_char];
  bind [{ control = true; meta = false; shift = false; code = Char(Uchar.of_char 'k') }] [Zed Kill_next_line];
  bind [{ control = true; meta = false; shift = false; code = Char(Uchar.of_char 'u') }] [Zed Kill_prev_line];
  bind [{ control = true; meta = false; shift = false; code = Char(Uchar.of_char 'n') }] [Zed Next_line];
  bind [{ control = true; meta = false; shift = false; code = Char(Uchar.of_char 'p') }] [Zed Prev_line];
  bind [{ control = true; meta = false; shift = false; code = Char(Uchar.of_char 'w') }] [Zed Kill];
  bind [{ control = true; meta = false; shift = false; code = Char(Uchar.of_char 'y') }] [Zed Yank];
  bind [{ control = false; meta = false; shift = false; code = Backspace }] [Zed Delete_prev_char];
  bind [{ control = false; meta = true; shift = false; code = Char(Uchar.of_char 'w') }] [Zed Copy];
  bind [{ control = false; meta = true; shift = false; code = Char(Uchar.of_char 'c') }] [Zed Capitalize_word];
  bind [{ control = false; meta = true; shift = false; code = Char(Uchar.of_char 'l') }] [Zed Lowercase_word];
  bind [{ control = false; meta = true; shift = false; code = Char(Uchar.of_char 'u') }] [Zed Uppercase_word];
  bind [{ control = false; meta = true; shift = false; code = Char(Uchar.of_char 'b') }] [Zed Prev_word];
  bind [{ control = false; meta = true; shift = false; code = Char(Uchar.of_char 'f') }] [Zed Next_word];
  bind [{ control = false; meta = true; shift = false; code = Right }] [Zed Next_word];
  bind [{ control = false; meta = true; shift = false; code = Left }] [Zed Prev_word];
  bind [{ control = true; meta = false; shift = false; code = Right }] [Zed Next_word];
  bind [{ control = true; meta = false; shift = false; code = Left }] [Zed Prev_word];
  bind [{ control = false; meta = true; shift = false; code = Backspace }] [Zed Kill_prev_word];
  bind [{ control = false; meta = true; shift = false; code = Delete }] [Zed Kill_prev_word];
  bind [{ control = true; meta = false; shift = false; code = Delete }] [Zed Kill_next_word];
  bind [{ control = false; meta = true; shift = false; code = Char(Uchar.of_char 'd') }] [Zed Kill_next_word];
  bind [{ control = true; meta = false; shift = false; code = Char(Uchar.of_char '_') }] [Zed Undo];
  bind [{ control = true; meta = false; shift = false; code = Char(Uchar.of_char 'x') }; { control = false; meta = false; shift = false; code = Char(Uchar.of_char '(') }] [Start_macro];
  bind [{ control = true; meta = false; shift = false; code = Char(Uchar.of_char 'x') }; { control = false; meta = false; shift = false; code = Char(Uchar.of_char ')') }] [Stop_macro];
  bind [{ control = true; meta = false; shift = false; code = Char(Uchar.of_char 'x') }; { control = false; meta = false; shift = false; code = Char(Uchar.of_char 'e') }] [Play_macro];
  bind [{ control = true; meta = false; shift = false; code = Char(Uchar.of_char 'g') }] [Cancel_macro];
  bind [{ control = true; meta = false; shift = false; code = Char(Uchar.of_char 'x') };
        { control = true; meta = false; shift = false; code = Char(Uchar.of_char 'k') };
        { control = false; meta = false; shift = false; code = Tab }] [Insert_macro_counter];
  bind [{ control = true; meta = false; shift = false; code = Char(Uchar.of_char 'x') };
        { control = true; meta = false; shift = false; code = Char(Uchar.of_char 'k') };
        { control = true; meta = false; shift = false; code = Char(Uchar.of_char 'a') }] [Add_macro_counter];
  bind [{ control = true; meta = false; shift = false; code = Char(Uchar.of_char 'x') };
        { control = true; meta = false; shift = false; code = Char(Uchar.of_char 'k') };
        { control = true; meta = false; shift = false; code = Char(Uchar.of_char 'c') }] [Set_macro_counter]

(* +-----------------------------------------------------------------+
   | Widgets                                                         |
   +-----------------------------------------------------------------+ *)

let clipboard = Zed_edit.new_clipboard ()
let macro = Zed_macro.create []

let dummy_engine = Zed_edit.create ()
let dummy_cursor = Zed_edit.new_cursor dummy_engine
let dummy_context = Zed_edit.context dummy_engine dummy_cursor
let newline = Zed_char.unsafe_of_uChar (Uchar.of_char '\n')

class scrollable = object
  inherit LTerm_widget.scrollable
  method! calculate_range page_size document_size = (document_size - page_size/2)
end

let default_match_word _ _ = None

class edit ?(clipboard = clipboard) ?(macro = macro) ?(size = { cols = 1; rows = 1 }) () =
  let locale, set_locale = S.create None in
object(self)
  inherit LTerm_widget.t "edit" as super

  val vscroll = new scrollable
  method vscroll = vscroll

  method clipboard = clipboard
  method macro = macro

  method! can_focus = true

  val mutable engine = dummy_engine
  method engine = engine

  val mutable cursor = dummy_cursor
  method cursor = cursor

  val mutable context = dummy_context
  method context = context

  method text = Zed_rope.to_string (Zed_edit.text engine)

  val mutable style = LTerm_style.none
  val mutable marked_style = LTerm_style.none
  val mutable current_line_style = LTerm_style.none
  method! update_resources =
    let rc = self#resource_class and resources = self#resources in
    style <- LTerm_resources.get_style rc resources;
    marked_style <- LTerm_resources.get_style (rc ^ ".marked") resources;
    current_line_style <- LTerm_resources.get_style (rc ^ ".current-line") resources

  method editable _pos _len = true
  method match_word = default_match_word
  method locale = S.value locale
  method set_locale locale = set_locale locale

  val mutable event = E.never
  val mutable resolver = None

  val mutable local_bindings = Bindings.empty
  method bind keys actions = local_bindings <- Bindings.add keys actions local_bindings

  val mutable shift_width = 0
  val mutable start = 0
  val mutable start_line = 0
  val mutable size = size

  method! size_request = size

  method private update_window_position =
    let line_set = Zed_edit.lines engine in
    let line_count = Zed_lines.count line_set in
    let cursor_offset = Zed_cursor.get_position cursor in
    let cursor_line = Zed_lines.line_index line_set cursor_offset in
    let cursor_column = cursor_offset - Zed_lines.line_start line_set cursor_line in
    let column_display= Zed_lines.force_width line_set (Zed_lines.line_start line_set cursor_line) cursor_column in


    (*** check cursor position is in view *)

    (* Horizontal check *)
    if column_display < shift_width || column_display >= shift_width + size.cols then begin

      shift_width <- max 0 (column_display - size.cols / 2);
    end;

    (* Vertical check *)
    let start_line' = Zed_lines.line_index line_set start in
    let start_line' =
      if cursor_line < start_line' || cursor_line >= start_line' + size.rows then begin
        (*let start_line' = max 0 (cursor_line - size.rows / 2) in*)
        let line_count = Zed_lines.count line_set in
        let start_line' = min line_count (max 0 (cursor_line - size.rows / 2)) in
        start <- Zed_lines.line_start line_set start_line';
        start_line'
      end else
        start_line'
    in
    (* document size *)
    if start_line <> start_line' then begin
      start_line <- start_line';
      vscroll#set_offset ~trigger_callback:false start_line
    end;
    vscroll#set_document_size (line_count+1);
    ()

  initializer
    engine <- (
      Zed_edit.create
        ~editable:(fun pos len -> self#editable pos len)
        ?match_word:(if self # match_word == default_match_word then None else Some self # match_word)
        ~clipboard
        ~locale
        ()
    );
    cursor <- Zed_edit.new_cursor engine;
    context <- Zed_edit.context engine cursor;
    Zed_edit.set_data engine (self :> edit);
    event <- E.map (fun _ ->
      self#update_window_position;
      self#queue_draw) (Zed_edit.update engine [cursor]);
    self#on_event
      (function
         | LTerm_event.Key key -> begin
             let res =
               match resolver with
               | Some res -> res
               | None -> Bindings.resolver [ Bindings.pack (fun x -> x) local_bindings
                                           ; Bindings.pack (fun x -> x) !bindings
                                           ]
             in
             match Bindings.resolve key res with
               | Bindings.Accepted actions ->
                   resolver <- None;
                   let rec exec = function
                     | Custom f :: actions ->
                         Zed_macro.add macro (Custom f);
                         f ();
                         exec actions
                     | Zed action :: actions ->
                         Zed_macro.add macro (Zed action);
                         Zed_edit.get_action action context;
                         exec actions
                     | Start_macro :: actions ->
                         Zed_macro.set_recording macro true;
                         exec actions
                     | Stop_macro :: actions ->
                         Zed_macro.set_recording macro false;
                         exec actions
                     | Cancel_macro :: actions ->
                         Zed_macro.cancel macro;
                         exec actions
                     | Play_macro :: actions ->
                         Zed_macro.cancel macro;
                         exec (Zed_macro.contents macro @ actions)
                     | Insert_macro_counter :: actions ->
                         Zed_macro.add macro Insert_macro_counter;
                         Zed_edit.insert context (Zed_rope.of_string (Zed_string.unsafe_of_utf8 (string_of_int (Zed_macro.get_counter macro))));
                         Zed_macro.add_counter macro 1;
                         exec actions
                     | (Add_macro_counter | Set_macro_counter) :: actions ->
                         exec actions
                     | [] ->
                         true
                   in
                   exec actions
               | Bindings.Continue res ->
                   resolver <- Some res;
                   true
               | Bindings.Rejected ->
                   if resolver = None then
                     match key with
                       | { control = false; meta = false; shift = false; code = Char ch } ->
                           Zed_edit.insert_char context ch;
                           true
                       | _ ->
                           false
                   else begin
                     resolver <- None;
                     false
                   end
           end
         | _ ->
             false)


  method! set_allocation rect =
    size <- size_of_rect rect;
    super#set_allocation rect;
    vscroll#set_page_size size.rows;
    start <- 0; shift_width <- 0; start_line <- 0;
    self#update_window_position

  initializer vscroll#on_offset_change (fun n ->

    (* find what line the cursor is currently on. *)
    let line_set = Zed_edit.lines engine in
    let cursor_offset = Zed_cursor.get_position cursor in
    let cursor_line = Zed_lines.line_index line_set cursor_offset in

    start_line <- n;
    start <- Zed_lines.line_start line_set start_line;

    if cursor_line < start_line then begin
      let d = start_line - cursor_line in
      Zed_edit.move_line context d (* first row *)
    end else if cursor_line >= start_line + size.rows then begin
      let line_count = Zed_lines.count line_set in
      let line = max 0 (min (line_count+1) (start_line + size.rows - 1)) in (* last row *)
      let d = line - cursor_line in
      Zed_edit.move_line context d
    end;
    self#queue_draw;
  )


  method! draw ctx _focused =
    let open LTerm_draw in

    let size = LTerm_draw.size ctx in

    let line_set = Zed_edit.lines engine in
    let cursor_offset = Zed_cursor.get_position cursor in
    let cursor_line = Zed_lines.line_index line_set cursor_offset in
    let cursor_column = cursor_offset - Zed_lines.line_start line_set cursor_line in

    (*** Drawing ***)

    (* Initialises points with the text style and spaces. *)
    fill ctx (Zed_char.unsafe_of_char ' ');
    fill_style ctx style;

    (*** Text drawing ***)

    let rec draw_line row col zip =
      if Zed_rope.Zip.at_eos zip then
        draw_eoi (row + 1)
      else
        let char, zip = Zed_rope.Zip.next zip in
        if char = newline then begin
          let row = row + 1 in
          if row < size.rows then begin_line row zip
        end else begin
          if col > size.cols then begin
            let row = row + 1 in
            if row < size.rows then skip_eol row zip
          end else begin
            draw_char ctx row col char;
            draw_line row (col + (Zed_char.width char)) zip
          end
        end

    and skip_eol row zip =
      if Zed_rope.Zip.at_eos zip then
        draw_eoi (row + 1)
      else
        let char, zip = Zed_rope.Zip.next zip in
        if char = newline then
          begin_line row zip
        else
          skip_eol row zip

    and skip_bol row zip remaining =
      if remaining <= 0 then
        draw_line row (-remaining) zip
      else if Zed_rope.Zip.at_eos zip then
        draw_eoi (row + 1)
      else
        let char, zip = Zed_rope.Zip.next zip in
        if char = newline then begin
          let row = row + 1 in
          if row < size.rows then begin_line row zip
        end else
          skip_bol row zip (remaining - (Zed_char.width char))

    and begin_line row zip =
      if Zed_rope.Zip.at_eos zip then
        draw_eoi row
      else if shift_width <> 0 then begin
        skip_bol row zip shift_width
      end else
        draw_line row 0 zip

    and draw_eoi _row =
      ()
    in

    let text = Zed_edit.text engine in

    begin_line 0 (Zed_rope.Zip.make_f text start);

    (* Colorize the current line. *)
    for col = 0 to size.cols - 1 do
      set_style (point ctx (cursor_line - start_line) col) current_line_style
    done;

    (* Colorize the selection if needed *)
    if Zed_edit.get_selection engine then begin
      let sel_offset = Zed_cursor.get_position (Zed_edit.mark engine) in
      let sel_line = Zed_lines.line_index line_set sel_offset in
      let sel_column = sel_offset - Zed_lines.line_start line_set sel_line in
      let line_a, column_a, line_b, column_b =
        if sel_offset < cursor_offset then
          (sel_line, sel_column, cursor_line, cursor_column)
        else
          (cursor_line, cursor_column, sel_line, sel_column)
      in
      let line_a, column_a =
        if line_a < start_line then
          (start_line, 0)
        else
          (line_a, column_a)
      in
      let line_b, column_b =
        if line_b >= start_line + size.rows then
          (start_line + size.rows - 1, size.cols - 1)
        else
          (line_b, column_b)
      in
      if line_a < start_line + size.rows && line_b >= start_line then begin
        let line_a = line_a - start_line and line_b = line_b - start_line in
        let column_a = column_a and column_b = column_b in
        if line_a = line_b then
          for column = column_a to column_b - 1 do
            set_style (point ctx line_a column) marked_style
          done
        else begin
          for column = column_a to size.cols - 1 do
            set_style (point ctx line_a column) marked_style
          done;
          for line = line_a + 1 to line_b - 1 do
            for column = 0 to size.cols - 1 do
              set_style (point ctx line column) marked_style
            done
          done;
          for column = 0 to column_b - 1 do
            set_style (point ctx line_b column) marked_style
          done
        end
      end
    end

  method! cursor_position =
    let line_set = Zed_edit.lines engine in
    let cursor_offset = Zed_cursor.get_position cursor in
    let cursor_line = Zed_lines.line_index line_set cursor_offset in
    let line_start= Zed_lines.line_start line_set cursor_line  in
    let start_line = Zed_lines.line_index line_set start in
    let col= Zed_lines.force_width line_set line_start (cursor_offset - line_start)
        - shift_width in
    Some { row = cursor_line - start_line; col }
end
