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

  let reset t = t := ""
end

let prompt ?validate ?default ?style message =
  let default_str = "******" in
  let default_str_opt = Option.map (fun _ -> default_str) default in
  Utils.print_prompt ?default:default_str_opt ?style message;
  Ansi.save_cursor ();
  let buf = Input_buffer.create () in
  let validate = match validate with None -> fun x -> Ok x | Some fn -> fn in
  let reset () =
    Ansi.restore_cursor ();
    Ansi.erase Ansi.Eol;
    Input_buffer.reset buf
  in
  let rec aux () =
    let ch = Char.code (input_char stdin) in
    match ch, default with
    | 10, Some default ->
      (* Enter *)
      if Input_buffer.is_empty buf then (
        Utils.erase_n_chars (3 + String.length default_str);
        print_endline default_str;
        flush stdout;
        default)
      else
        let input = Input_buffer.get buf in
        (match validate input with
        | Ok output ->
          Utils.erase_n_chars (3 + String.length default_str);
          print_endline default_str;
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
      Utils.print_prompt ?default:default_str_opt ?style message;
      Ansi.save_cursor ();
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
      Input_buffer.rm_last_char buf;
      aux ()
    | code, _ ->
      Input_buffer.add_char buf (Char.chr code);
      aux ()
  in
  Utils.with_raw Unix.stdin aux
