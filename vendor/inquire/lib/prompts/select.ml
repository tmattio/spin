open React
open Lwt
open LTerm_text

type input =
  | Enter
  | Up
  | Down

let rec read_input term =
  LTerm.read_event term >>= function
  | LTerm_event.Key
      { LTerm_key.code = LTerm_key.Char ch; LTerm_key.control = true; _ }
    when Uchar.equal ch (Uchar.of_char 'c') ->
    (* Exit on Ctrl+C *)
    Lwt.fail (Failure "interrupted")
  | LTerm_event.Key { code = LTerm_key.Enter; _ } ->
    Lwt.return Enter
  | LTerm_event.Key { code = LTerm_key.Left; _ }
  | LTerm_event.Key { code = LTerm_key.Up; _ } ->
    Lwt.return Up
  | LTerm_event.Key { code = LTerm_key.Right; _ }
  | LTerm_event.Key { code = LTerm_key.Down; _ } ->
    Lwt.return Down
  | _ ->
    read_input term

let select ?default ~term ~impl:(module I : Impl.M) options =
  let default = Utils.index_of_default ?default options in
  let rec aux current =
    LTerm.clear_line_prev term >>= fun () ->
    let n_break_lines = List.length options in
    LTerm.move term (-n_break_lines) 0 >>= fun () ->
    let select_str = I.make_select options ~current in
    LTerm.fprints term select_str >>= fun () ->
    read_input term >>= function
    | Enter ->
      Lwt.return current
    | Up ->
      aux (max 0 (current - 1))
    | Down ->
      aux (min (List.length options - 1) (current + 1))
  in
  let select_str = I.make_select options ~current:default in
  LTerm.fprints term select_str >>= fun () -> aux default

let prompt ~impl:(module I : Impl.M) ?default ~options message =
  LTerm_inputrc.load () >>= fun () ->
  Lazy.force LTerm.stdout >>= fun term ->
  LTerm.enter_raw_mode term >>= fun mode ->
  LTerm.hide_cursor term >>= fun () ->
  let prompt = I.make_prompt message in
  LTerm.fprintls term prompt >>= fun () ->
  Lwt.finalize
    (fun () ->
      select options ?default ~term ~impl:(module I) >>= fun v ->
      Lwt.return (List.nth options v))
    (fun () ->
      LTerm.leave_raw_mode term mode >>= fun () -> LTerm.show_cursor term)
