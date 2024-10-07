module Input_buffer = struct
  type t = { mutable content : string; mutable cursor : int }

  let create () = { content = ""; cursor = 0 }
  let is_empty t = t.content = ""

  let add_char t chr =
    let left = String.sub t.content 0 t.cursor in
    let right =
      String.sub t.content t.cursor (String.length t.content - t.cursor)
    in
    t.content <- left ^ String.make 1 chr ^ right;
    t.cursor <- t.cursor + 1

  let rm_last_char t =
    if t.cursor > 0 then (
      let left = String.sub t.content 0 (t.cursor - 1) in
      let right =
        String.sub t.content t.cursor (String.length t.content - t.cursor)
      in
      t.content <- left ^ right;
      t.cursor <- t.cursor - 1)

  let get t = t.content
  let get_cursor t = t.cursor
  let set_cursor t pos = t.cursor <- max 0 (min pos (String.length t.content))
  let move_cursor t delta = set_cursor t (t.cursor + delta)

  let print t =
    print_string t.content;
    flush stdout

  let print_from_cursor t =
    let content = t.content in
    let len = String.length content in
    print_string (String.sub content t.cursor (len - t.cursor));
    Ansi.move_cursor (-(len - t.cursor)) 0;
    flush stdout

  let reset t =
    t.content <- "";
    t.cursor <- 0

  let set t str =
    t.content <- str;
    t.cursor <- String.length str

  let get_length t = String.length t.content
end

type input_state = Normal | Escape | CSI

let prompt ?validate ?default ?style message =
  Utils.print_prompt ?default ?style message;
  let buf = Input_buffer.create () in
  let validate = match validate with None -> fun x -> Ok x | Some fn -> fn in
  let reset () =
    Ansi.move_cursor (-1 * Input_buffer.get_cursor buf) 0;
    Ansi.erase Ansi.Eol;
    Input_buffer.reset buf
  in
  let print_input () =
    Ansi.move_cursor (-1 * Input_buffer.get_cursor buf) 0;
    Input_buffer.print buf;
    Ansi.move_cursor
      (-1 * (String.length (Input_buffer.get buf) - Input_buffer.get_cursor buf))
      0
  in
  let remove_last_char () =
    if (not (Input_buffer.is_empty buf)) && Input_buffer.get_cursor buf > 0 then
      Input_buffer.rm_last_char buf;
    Ansi.move_cursor (-1) 0;
    Ansi.erase Ansi.Eol;
    print_input ()
  in
  let rec aux state =
    let ch = input_char stdin in
    match (state, Char.code ch) with
    | Normal, 27 ->
      (* ESC *)
      aux Escape
    | Escape, 91 ->
      (* [ *)
      aux CSI
    | CSI, 65 ->
      (* Up arrow *)
      (* Handle up arrow - for now, do nothing *)
      aux Normal
    | CSI, 66 ->
      (* Down arrow *)
      (* Handle down arrow - for now, do nothing *)
      aux Normal
    | CSI, 67 ->
      (* Right arrow *)
      if Input_buffer.get_cursor buf < Input_buffer.get_length buf then (
        Input_buffer.move_cursor buf 1;
        Ansi.move_cursor 1 0);
      aux Normal
    | CSI, 68 ->
      (* Left arrow *)
      if Input_buffer.get_cursor buf > 0 then (
        Input_buffer.move_cursor buf (-1);
        Ansi.move_cursor (-1) 0);
      aux Normal
    | Escape, _ ->
      (* Escape followed by anything other than [ is treated as literal ESC +
         char *)
      Input_buffer.add_char buf (Char.chr 27);
      Input_buffer.add_char buf ch;
      print_string "\x1B";
      print_char ch;
      flush stdout;
      aux Normal
    | CSI, _ ->
      (* CSI followed by anything other than arrow codes is treated as literal
         ESC [ + char *)
      Input_buffer.add_char buf (Char.chr 27);
      Input_buffer.add_char buf '[';
      Input_buffer.add_char buf ch;
      print_string "\x1B[";
      print_char ch;
      flush stdout;
      aux Normal
    | Normal, 10 -> (
      (* Enter *)
      match default with
      | Some default when Input_buffer.is_empty buf ->
        Ansi.erase Ansi.Below;
        Utils.erase_n_chars (3 + String.length default);
        print_endline default;
        flush stdout;
        default
      | _ -> (
        let input = Input_buffer.get buf in
        match validate input with
        | Ok output ->
          Ansi.erase Ansi.Below;
          (match default with
          | Some d ->
            Utils.erase_n_chars (3 + String.length d + String.length input)
          | None -> ());
          print_endline output;
          flush stdout;
          output
        | Error err ->
          print_string "\n";
          flush stdout;
          Utils.print_err err;
          Ansi.move_cursor 0 (-1);
          Ansi.move_bol ();
          Utils.print_prompt ?default ?style message;
          Ansi.erase Ansi.Eol;
          Input_buffer.reset buf;
          aux Normal))
    | Normal, 12 ->
      (* ^L (Form feed, clear screen) *)
      Ansi.erase Ansi.Screen;
      Ansi.set_cursor 1 1;
      Utils.print_prompt ?default ?style message;
      Input_buffer.print buf;
      Ansi.move_cursor
        (-1
        * (String.length (Input_buffer.get buf) - Input_buffer.get_cursor buf))
        0;
      aux Normal
    | Normal, 3 | Normal, 4 ->
      (* ^C (interrupt) and ^D (EOF) *)
      print_string "\n";
      Ansi.erase Ansi.Eol;
      flush stdout;
      Utils.user_interrupt ()
    | Normal, 1 ->
      (* ^A (move to beginning of line) *)
      let current_pos = Input_buffer.get_cursor buf in
      Input_buffer.set_cursor buf 0;
      Ansi.move_cursor (-current_pos) 0;
      aux Normal
    | Normal, 5 ->
      (* ^E (move to end of line) *)
      let current_pos = Input_buffer.get_cursor buf in
      let end_pos = String.length (Input_buffer.get buf) in
      Input_buffer.set_cursor buf end_pos;
      Ansi.move_cursor (end_pos - current_pos) 0;
      aux Normal
    | Normal, 11 ->
      (* ^K (kill to end of line) *)
      let current_pos = Input_buffer.get_cursor buf in
      let current = Input_buffer.get buf in
      Input_buffer.set buf (String.sub current 0 current_pos);
      Ansi.erase Ansi.Eol;
      aux Normal
    | Normal, 21 ->
      (* ^U (kill to beginning of line) *)
      reset ();
      aux Normal
    | Normal, 23 ->
      (* ^W (delete word) *)
      let current = Input_buffer.get buf in
      let cursor = Input_buffer.get_cursor buf in
      let rec find_word_start i =
        if i = 0 then 0
        else if current.[i - 1] = ' ' then i
        else find_word_start (i - 1)
      in
      let word_start = find_word_start cursor in
      Input_buffer.set buf
        (String.sub current 0 word_start
        ^ String.sub current cursor (String.length current - cursor));
      Input_buffer.set_cursor buf word_start;
      Ansi.move_cursor (-1 * (cursor - word_start)) 0;
      Ansi.erase Ansi.Eol;
      print_input ();
      aux Normal
    | Normal, 127 ->
      (* DEL (backspace) *)
      if (not (Input_buffer.is_empty buf)) && Input_buffer.get_cursor buf > 0
      then remove_last_char ();
      aux Normal
    | Normal, code when code < 32 ->
      (* Ignore other control characters *)
      aux Normal
    | Normal, _ ->
      Input_buffer.add_char buf ch;
      print_char ch;
      Input_buffer.print_from_cursor buf;
      aux Normal
  in
  Utils.with_raw Unix.stdin (fun () -> aux Normal)
