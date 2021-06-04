let print_options ?(style = Style.default) ~selected options =
  List.iteri
    (fun i opt ->
      if i = selected then
        Printf.printf
          " %s %i) %s"
          (Ansi.sprintf style.Style.qmark_format "%s" style.Style.pointer_icon)
          (i + 1)
          opt
      else
        Printf.printf "   %i) %s" (i + 1) opt;
      if not (i + 1 = List.length options) then print_string "\n")
    options;
  flush stdout

let print_prompt ?style message =
  Utils.print_prompt ?style message;
  flush stdout

let prompt ?default ?style ~options message =
  let selected =
    match default with
    | Some v when v < List.length options ->
      ref v
    | _ ->
      ref 0
  in
  let print_options () = print_options ~selected:!selected options in
  let reset () =
    let erase_n_lines = function
      | 0 ->
        ()
      | n ->
        Ansi.move_bol ();
        Ansi.move_cursor 0 (-1 * (n - 1));
        Ansi.erase Ansi.Below;
        flush stdout
    in
    erase_n_lines (List.length options)
  in
  let up () =
    selected := max 0 (!selected - 1);
    reset ();
    print_options ()
  in
  let down () =
    selected := min (List.length options - 1) (!selected + 1);
    reset ();
    print_options ()
  in
  let select i =
    selected := i;
    reset ();
    print_options ()
  in
  print_prompt ?style message;
  print_string "\n";
  print_options ();
  flush stdout;
  let rec aux () =
    let buf = Bytes.create 3 in
    let size = input stdin buf 0 3 in
    match
      ( size
      , Char.code (Bytes.get buf 0)
      , Char.code (Bytes.get buf 1)
      , Char.code (Bytes.get buf 2) )
    with
    | 1, 10, _, _ ->
      (* Enter *)
      reset ();
      Ansi.move_cursor 0 (-1);
      Ansi.erase Ansi.Eol;
      print_prompt ?style message;
      let input = List.nth options !selected in
      print_string input;
      print_string "\n";
      flush stdout;
      input
    | 1, 12, _, _ ->
      (* Handle ^L *)
      Ansi.erase Ansi.Screen;
      Ansi.set_cursor 1 1;
      print_prompt ?style message;
      print_string "\n";
      print_options ();
      aux ()
    | 1, (3 | 4), _, _ ->
      (* Handle ^C and ^D *)
      print_string "\n";
      flush stdout;
      (* Exit with an exception so we can catch it and revert the changes on
         stdin. *)
      Utils.user_interrupt ()
    | 3, 27, 91, 65 ->
      (* UP *)
      up ();
      aux ()
    | 3, 27, 91, 66 ->
      (* DOWN *)
      down ();
      aux ()
    | 1, code, _, _ ->
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
    | _ ->
      aux ()
  in
  Utils.with_raw ~hide_cursor:true Unix.stdin aux
