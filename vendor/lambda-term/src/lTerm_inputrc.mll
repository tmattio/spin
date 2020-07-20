(*
 * lTerm_inputrc.mll
 * -----------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

{
  open LTerm_key

  let return, (>>=) = Lwt.return, Lwt.(>>=)

  exception Parse_error of string * int * string

  let parse_error src line fmt = Printf.ksprintf (fun msg -> raise (Parse_error (src, line, msg))) fmt

  let handle_edit_action src line seq actions =
    if actions = [] then
      LTerm_edit.unbind seq
    else
      let actions =
        List.map
          (fun str ->
             try
               LTerm_edit.action_of_name str
             with Not_found ->
               parse_error src line "invalid edit action %S" str)
          actions
      in
      LTerm_edit.bind seq actions

  let handle_read_line_action src line seq actions =
    if actions = [] then
      LTerm_read_line.unbind seq
    else
      let actions =
        List.map
          (fun str ->
             try
               LTerm_read_line.action_of_name str
             with Not_found ->
               parse_error src line "invalid read-line action %S" str)
          actions
      in
      LTerm_read_line.bind seq actions

  type line =
    | Comment
    | Section of string
    | Binding of LTerm_key.t list * string list
    | Error of string

  let dummy_key = { control = false; meta = false; shift = false; code = Escape }
}

let blank = [' ' '\t']

rule line = parse
  | blank* eof
      { Comment }
  | blank* '#' [^'\n']* eof
      { Comment }
  | blank* '[' blank* ([^'\n' ' ' '\t' ']']* as section) blank* ']' blank* ('#' [^'\n']*)? eof
      { Section section }
  | blank*
      { sequence dummy_key [] lexbuf }

and sequence key seq = parse
  | "C-"
      { sequence { key with control = true } seq lexbuf }
  | "M-"
      { sequence { key with meta = true } seq lexbuf }
  | "S-"
      { sequence { key with shift = true } seq lexbuf }
  | "enter" (blank+ | ':' as sep)
      {
        let seq = { key with code = Enter } :: seq in
        if sep = ":" then
          actions (List.rev seq) [] lexbuf
        else
          sequence dummy_key seq lexbuf
      }
  | "escape" (blank+ | ':' as sep)
      {
        let seq = { key with code = Escape } :: seq in
        if sep = ":" then
          actions (List.rev seq) [] lexbuf
        else
          sequence dummy_key seq lexbuf
      }
  | "tab" (blank+ | ':' as sep)
      {
        let seq = { key with code = Tab } :: seq in
        if sep = ":" then
          actions (List.rev seq) [] lexbuf
        else
          sequence dummy_key seq lexbuf
      }
  | "up" (blank+ | ':' as sep)
      {
        let seq = { key with code = Up } :: seq in
        if sep = ":" then
          actions (List.rev seq) [] lexbuf
        else
          sequence dummy_key seq lexbuf
      }
  | "down" (blank+ | ':' as sep)
      {
        let seq = { key with code = Down } :: seq in
        if sep = ":" then
          actions (List.rev seq) [] lexbuf
        else
          sequence dummy_key seq lexbuf
      }
  | "left" (blank+ | ':' as sep)
      {
        let seq = { key with code = Left } :: seq in
        if sep = ":" then
          actions (List.rev seq) [] lexbuf
        else
          sequence dummy_key seq lexbuf
      }
  | "right" (blank+ | ':' as sep)
      {
        let seq = { key with code = Right } :: seq in
        if sep = ":" then
          actions (List.rev seq) [] lexbuf
        else
          sequence dummy_key seq lexbuf
      }
  | "f1" (blank+ | ':' as sep)
      {
        let seq = { key with code = F1 } :: seq in
        if sep = ":" then
          actions (List.rev seq) [] lexbuf
        else
          sequence dummy_key seq lexbuf
      }
  | "f2" (blank+ | ':' as sep)
      {
        let seq = { key with code = F2 } :: seq in
        if sep = ":" then
          actions (List.rev seq) [] lexbuf
        else
          sequence dummy_key seq lexbuf
      }
  | "f3" (blank+ | ':' as sep)
      {
        let seq = { key with code = F3 } :: seq in
        if sep = ":" then
          actions (List.rev seq) [] lexbuf
        else
          sequence dummy_key seq lexbuf
      }
  | "f4" (blank+ | ':' as sep)
      {
        let seq = { key with code = F4 } :: seq in
        if sep = ":" then
          actions (List.rev seq) [] lexbuf
        else
          sequence dummy_key seq lexbuf
      }
  | "f5" (blank+ | ':' as sep)
      {
        let seq = { key with code = F5 } :: seq in
        if sep = ":" then
          actions (List.rev seq) [] lexbuf
        else
          sequence dummy_key seq lexbuf
      }
  | "f6" (blank+ | ':' as sep)
      {
        let seq = { key with code = F6 } :: seq in
        if sep = ":" then
          actions (List.rev seq) [] lexbuf
        else
          sequence dummy_key seq lexbuf
      }
  | "f7" (blank+ | ':' as sep)
      {
        let seq = { key with code = F7 } :: seq in
        if sep = ":" then
          actions (List.rev seq) [] lexbuf
        else
          sequence dummy_key seq lexbuf
      }
  | "f8" (blank+ | ':' as sep)
      {
        let seq = { key with code = F8 } :: seq in
        if sep = ":" then
          actions (List.rev seq) [] lexbuf
        else
          sequence dummy_key seq lexbuf
      }
  | "f9" (blank+ | ':' as sep)
      {
        let seq = { key with code = F9 } :: seq in
        if sep = ":" then
          actions (List.rev seq) [] lexbuf
        else
          sequence dummy_key seq lexbuf
      }
  | "f10" (blank+ | ':' as sep)
      {
        let seq = { key with code = F10 } :: seq in
        if sep = ":" then
          actions (List.rev seq) [] lexbuf
        else
          sequence dummy_key seq lexbuf
      }
  | "f11" (blank+ | ':' as sep)
      {
        let seq = { key with code = F11 } :: seq in
        if sep = ":" then
          actions (List.rev seq) [] lexbuf
        else
          sequence dummy_key seq lexbuf
      }
  | "f12" (blank+ | ':' as sep)
      {
        let seq = { key with code = F12 } :: seq in
        if sep = ":" then
          actions (List.rev seq) [] lexbuf
        else
          sequence dummy_key seq lexbuf
      }
  | "next" (blank+ | ':' as sep)
      {
        let seq = { key with code = Next_page } :: seq in
        if sep = ":" then
          actions (List.rev seq) [] lexbuf
        else
          sequence dummy_key seq lexbuf
      }
  | "prev" (blank+ | ':' as sep)
      {
        let seq = { key with code = Prev_page } :: seq in
        if sep = ":" then
          actions (List.rev seq) [] lexbuf
        else
          sequence dummy_key seq lexbuf
      }
  | "home" (blank+ | ':' as sep)
      {
        let seq = { key with code = Home } :: seq in
        if sep = ":" then
          actions (List.rev seq) [] lexbuf
        else
          sequence dummy_key seq lexbuf
      }
  | "end" (blank+ | ':' as sep)
      {
        let seq = { key with code = End } :: seq in
        if sep = ":" then
          actions (List.rev seq) [] lexbuf
        else
          sequence dummy_key seq lexbuf
      }
  | "insert" (blank+ | ':' as sep)
      {
        let seq = { key with code = Insert } :: seq in
        if sep = ":" then
          actions (List.rev seq) [] lexbuf
        else
          sequence dummy_key seq lexbuf
      }
  | "delete" (blank+ | ':' as sep)
      {
        let seq = { key with code = Delete } :: seq in
        if sep = ":" then
          actions (List.rev seq) [] lexbuf
        else
          sequence dummy_key seq lexbuf
      }
  | "backspace" (blank+ | ':' as sep)
      {
        let seq = { key with code = Backspace } :: seq in
        if sep = ":" then
          actions (List.rev seq) [] lexbuf
        else
          sequence dummy_key seq lexbuf
      }
  | [ 'a'-'z' 'A'-'Z' '0'-'9' '_' '(' ')' '[' ']' '{' '}' '~' '&' '$' '*' '%' '!' '?' ',' ';' '/' '\\' '.' '@' '=' '+' '-' '^' ] as ch (blank+ | ':' as sep)
      {
        let seq = { key with code = Char(Uchar.of_char ch) } :: seq in
        if sep = ":" then
          actions (List.rev seq) [] lexbuf
        else
          sequence dummy_key seq lexbuf
      }
  | "U+" (['a'-'f' 'A'-'F' '0'-'9']+ as hexa) (blank+ | ':' as sep)
      {
        let code = ref 0 in
        for i = 0 to String.length hexa - 1 do
          let ch = hexa.[i] in
          code := !code * 16 +
            (match ch with
               | '0' .. '9' -> Char.code ch - Char.code '0'
               | 'A' .. 'F' -> Char.code ch - Char.code 'A' + 10
               | 'a' .. 'f' -> Char.code ch - Char.code 'a' + 10
               | _ -> assert false)
        done;
        match try Some (Uchar.of_int !code) with _ -> None with
          | Some ch ->
              let seq = { key with code = Char ch } :: seq in
              if sep = ":" then
                actions (List.rev seq) [] lexbuf
              else
                sequence dummy_key seq lexbuf
          | None ->
              Error (Printf.sprintf "invalid unicode character U+%s" hexa)
      }
  | ""
      { Error "parsing error in key sequence" }

and actions seq l = parse
  | blank* ('#' [^'\n']*)? eof
      { Binding (seq, List.rev l) }
  | blank* (['a'-'z' 'A'-'Z' '-']+ ('(' [^')' '\n']* ')')? as action)
      { comma_actions seq (action :: l) lexbuf }
  | ""
      { Error "parsing error in actions" }

and comma_actions seq l = parse
  | blank* ','
      { actions seq l lexbuf }
  | blank* ('#' [^'\n']*)? eof
      { Binding (seq, List.rev l) }
  | ""
      { Error "parsing error in actions" }

{
  let default =
    LTerm_resources.xdgbd_file
      ~loc:LTerm_resources.Config
      ~allow_legacy_location:true
      ".lambda-term-inputrc"

  let load ?(file = default) () =
    Lwt.catch (fun () ->
      Lwt_io.open_file ~mode:Lwt_io.input file >>= fun ic ->
      let rec loop num handler =
        Lwt_io.read_line_opt ic >>= fun input_line ->
        match input_line with
          | None ->
              return ()
          | Some str ->
              match line (Lexing.from_string str) with
                | Comment ->
                    loop (num + 1) handler
                | Section "edit" ->
                    loop (num + 1) handle_edit_action
                | Section "read-line" ->
                    loop (num + 1) handle_read_line_action
                | Section section ->
                    parse_error file num "invalid section %S" section
                | Binding (seq, actions) ->
                    handler file num seq actions;
                    loop (num + 1) handler
                | Error msg ->
                    raise (Parse_error (file, num, msg))
      in
      Lwt.finalize
        (fun () -> loop 1 handle_edit_action)
        (fun () -> Lwt_io.close ic))
      (function
      | Unix.Unix_error(Unix.ENOENT, _, _) ->
          return ()
      | exn -> Lwt.fail exn)
}
