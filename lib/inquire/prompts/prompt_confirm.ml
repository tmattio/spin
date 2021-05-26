let prompt_auto_enter ?default print_prompt =
  print_prompt ();
  let rec aux () =
    let ch = Char.code (input_char stdin) in
    match ch, default with
    | 89, _ | 121, _ ->
      (* 'Y' | 'y' *)
      Utils.erase_n_chars 6;
      print_endline "Yes";
      flush stdout;
      true
    | 78, _ | 110, _ ->
      (* 'N' | 'n' *)
      Utils.erase_n_chars 6;
      print_endline "No";
      flush stdout;
      false
    | 10, Some default ->
      (* Enter *)
      Utils.erase_n_chars 6;
      if default then
        print_endline "Yes"
      else
        print_endline "No";
      flush stdout;
      default
    | 10, None ->
      (* Enter *)
      aux ()
    | 12, _ ->
      (* Handle ^L *)
      Ansi.erase Ansi.Screen;
      Ansi.set_cursor 1 1;
      print_prompt ();
      aux ()
    | 3, _ | 4, _ ->
      (* Handle ^C and ^D *)
      print_string "\n";
      flush stdout;
      (* Exit with an exception so we can catch it and revert the changes on
         stdin. *)
      Utils.user_interrupt ()
    | _ ->
      aux ()
  in
  Utils.with_raw Unix.stdin aux

let prompt_no_auto_enter ?default print_prompt =
  print_prompt ();
  let print_selection ~current selection =
    let () =
      match current with
      | Some true ->
        (* Erase "Yes" *)
        Utils.erase_n_chars 3
      | Some false ->
        (* Erase "No" *)
        Utils.erase_n_chars 2
      | None ->
        ()
    in
    if selection then
      print_string "Yes"
    else
      print_string "No";
    flush stdout
  in
  let rec aux selection =
    let ch = Char.code (input_char stdin) in
    match ch with
    | 89 | 121 ->
      (* 'Y' | 'y' *)
      print_selection ~current:selection true;
      aux (Some true)
    | 78 | 110 ->
      (* 'N' | 'n' *)
      print_selection ~current:selection false;
      aux (Some false)
    | 10 ->
      (match selection, default with
      | Some true, _ ->
        (* Erase current selection with default tooltip *)
        Utils.erase_n_chars 9;
        print_string "Yes\n";
        flush stdout;
        true
      | None, Some true ->
        (* Erase current selection with default tooltip *)
        (match default with Some _ -> Utils.erase_n_chars 6 | None -> ());
        print_string "Yes\n";
        flush stdout;
        true
      | Some false, _ ->
        (* Erase current selection with default tooltip *)
        Utils.erase_n_chars 8;
        print_string "No\n";
        flush stdout;
        false
      | None, Some false ->
        (* Erase current selection with default tooltip *)
        (match default with Some _ -> Utils.erase_n_chars 6 | None -> ());
        print_string "No\n";
        flush stdout;
        false
      | None, None ->
        aux None)
    | 12 ->
      (* Handle ^L *)
      Ansi.erase Ansi.Screen;
      Ansi.set_cursor 1 1;
      print_prompt ();
      Option.iter
        (fun selection -> print_selection ~current:None selection)
        selection;
      aux selection
    | 3 ->
      (* Handle ^C *)
      print_endline "\n\nCancelled by user\n";
      (* Exit with an exception so we can catch it and revert the changes on
         stdin. *)
      Utils.exit 130
    | _ ->
      aux selection
  in
  Utils.with_raw Unix.stdin (fun () -> aux None)

let prompt ?default ?(auto_enter = true) ?style message =
  let default_str =
    match default with
    | Some true ->
      "Y/n"
    | Some false ->
      "y/N"
    | None ->
      "y/n"
  in
  let print_prompt () =
    Utils.print_prompt ~default:default_str ?style message
  in
  if auto_enter then
    prompt_auto_enter ?default print_prompt
  else
    prompt_no_auto_enter ?default print_prompt
