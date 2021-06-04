module Input_buffer = struct
  let create () = ref ""

  let is_empty t = !t = ""

  let add_char t chr = t := !t ^ Char.escaped chr

  let rm_last_char t =
    if is_empty t then
      ()
    else
      t := String.sub !t 0 (String.length !t - 1)

  let get t = !t

  let print t =
    let input = !t in
    print_string input;
    flush stdout

  let reset t = t := ""
end

let prompt ?validate ?default ?style message =
  Utils.print_prompt ?default ?style message;
  let buf = Input_buffer.create () in
  let validate = match validate with None -> fun x -> Ok x | Some fn -> fn in
  let reset () =
    let len = String.length @@ Input_buffer.get buf in
    Ansi.move_cursor (-1 * len) 0;
    Ansi.erase Ansi.Eol;
    Input_buffer.reset buf
  in
  let print_input () = Input_buffer.print buf in
  let remove_last_char () =
    match Input_buffer.get buf with
    | "" ->
      ()
    | _ ->
      Input_buffer.rm_last_char buf;
      Ansi.move_cursor (-1) 0;
      Ansi.erase Ansi.Eol
  in
  let rec aux () =
    let ch = Char.code (input_char stdin) in
    match ch, default with
    | 10, Some default ->
      (* Enter *)
      if Input_buffer.is_empty buf then (
        Utils.erase_n_chars (3 + String.length default);
        print_endline default;
        flush stdout;
        default)
      else
        let input = Input_buffer.get buf in
        (match validate input with
        | Ok output ->
          Utils.erase_n_chars (3 + String.length default + String.length input);
          print_endline output;
          flush stdout;
          output
        | Error err ->
          print_string "\n";
          flush stdout;
          Utils.print_err err;
          reset ();
          aux ())
    | 10, None when Input_buffer.is_empty buf ->
      (* Enter, no input *)
      aux ()
    | 10, None ->
      (* Enter, with input *)
      let input = Input_buffer.get buf in
      (match validate input with
      | Ok output ->
        print_string "\n";
        flush stdout;
        output
      | Error err ->
        print_string "\n";
        flush stdout;
        Utils.print_err err;
        reset ();
        aux ())
    | 12, _ ->
      (* Handle ^L *)
      Ansi.erase Ansi.Screen;
      Ansi.set_cursor 1 1;
      Utils.print_prompt ?default ?style message;
      print_input ();
      aux ()
    | 3, _ | 4, _ ->
      (* Handle ^C and ^D *)
      print_string "\n";
      flush stdout;
      (* Exit with an exception so we can catch it and revert the changes on
         stdin. *)
      Utils.user_interrupt ()
    | 127, _ ->
      (* DEL *)
      remove_last_char ();
      aux ()
    | code, _ ->
      Input_buffer.add_char buf (Char.chr code);
      print_char (Char.chr code);
      flush stdout;
      aux ()
  in
  Utils.with_raw Unix.stdin aux
