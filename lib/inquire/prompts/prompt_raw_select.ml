let print_options ?(style = Style.default) ~selected options =
  List.iteri
    (fun i opt ->
      if Some i = selected then
        Printf.printf
          " %s %i) %s"
          (Ansi.sprintf style.Style.qmark_format "%s" style.Style.pointer_icon)
          (i + 1)
          opt
      else
        Printf.printf "   %i) %s" (i + 1) opt;
      if not (i + 1 = List.length options) then print_string "\n")
    options;
  print_string "\n Answer: ";
  flush stdout

let print_prompt ?style message =
  Utils.print_prompt ?style message;
  flush stdout

let prompt ?default ?style ~options message =
  let input =
    match default with
    | Some v when v < List.length options ->
      ref (Some v)
    | _ ->
      ref None
  in
  let print_options () = print_options ~selected:!input options in
  let print_input () =
    match !input with
    | None ->
      ()
    | Some i ->
      print_int (i + 1);
      flush stdout
  in
  let reset () =
    let erase_n_lines = function
      | 0 ->
        ()
      | n ->
        Ansi.move_bol ();
        Ansi.move_cursor 0 (-1 * n);
        Ansi.erase Ansi.Below;
        flush stdout
    in
    erase_n_lines (List.length options)
  in
  let select i =
    input := Some i;
    reset ();
    print_options ();
    print_input ()
  in
  print_prompt ?style message;
  print_string "\n";
  print_options ();
  print_input ();
  let rec aux () =
    let ch = Char.code (input_char stdin) in
    match ch, !input with
    | 10, Some input ->
      (* Enter *)
      reset ();
      Ansi.move_cursor 0 (-1);
      Ansi.erase Ansi.Eol;
      print_prompt ?style message;
      let input = List.nth options input in
      print_string input;
      print_string "\n";
      flush stdout;
      input
    | 12, _ ->
      (* Handle ^L *)
      Ansi.erase Ansi.Screen;
      Ansi.set_cursor 1 1;
      print_prompt ?style message;
      print_string "\n";
      print_options ();
      print_input ();
      aux ()
    | 3, _ | 4, _ ->
      (* Handle ^C and ^D *)
      print_string "\n";
      flush stdout;
      (* Exit with an exception so we can catch it and revert the changes on
         stdin. *)
      Utils.user_interrupt ()
    | code, _ ->
      (match Char.chr code with
      | '1' when List.length options >= 1 ->
        select 0
      | '2' when List.length options >= 2 ->
        select 1
      | '3' when List.length options >= 3 ->
        select 2
      | '4' when List.length options >= 4 ->
        select 3
      | '5' when List.length options >= 5 ->
        select 4
      | '6' when List.length options >= 6 ->
        select 5
      | '7' when List.length options >= 7 ->
        select 6
      | '8' when List.length options >= 8 ->
        select 7
      | '9' when List.length options >= 9 ->
        select 8
      | _ ->
        ());
      aux ()
  in
  Utils.with_raw Unix.stdin aux
