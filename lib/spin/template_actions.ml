type command =
  { name : string
  ; args : string list
  }

type action =
  | Run of command
  | Refmt of string list

type t =
  { message : string option
  ; actions : action list
  }

let of_dec ~context (dec_actions : Dec_template.Actions.t) =
  let open Lwt.Syntax in
  let* message =
    match dec_actions.message with
    | Some message ->
      let+ evaluated = Template_expr.eval message ~context in
      Some evaluated
    | None ->
      Lwt.return None
  in
  let+ actions =
    Spin_lwt.fold_left dec_actions.actions ~f:(function
        | Dec_template.Actions.Run { name; args } ->
          Run { name; args } |> Lwt.return
        | Dec_template.Actions.Refmt files ->
          let+ files =
            Spin_lwt.fold_left files ~f:(Template_expr.eval ~context)
          in
          Refmt files)
  in
  { message; actions }

let action_run ~root_path cmd =
  Logs.debug (fun m ->
      m "Running %s %s" cmd.name (String.concat cmd.args ~sep:" "));
  Spin_lwt.with_chdir ~dir:root_path (fun () ->
      Spin_lwt.exec_with_logs cmd.name cmd.args)
  |> Lwt_result.map_err (fun err -> Spin_error.failed_to_generate err)

let action_refmt ~root_path globs =
  let files = Spin_sys.ls_dir root_path in
  List.iter files ~f:(fun input_path ->
      Logs.debug (fun m -> m "Running refmt on %s" input_path);
      let normalized_path =
        String.chop_prefix_exn input_path ~prefix:root_path
        |> String.substr_replace_all ~pattern:"\\" ~with_:"/"
      in
      if Glob.matches_globs normalized_path ~globs then (
        Spin_refmt.convert input_path;
        Caml.Sys.remove input_path)
      else
        ())

let run ~path t =
  let open Lwt_result.Syntax in
  let* () =
    match t.message with
    | Some message ->
      Logs_lwt.app (fun m -> m "%s" message) |> Lwt_result.ok
    | None ->
      Lwt_result.return ()
  in
  let* () =
    List.fold_left t.actions ~init:(Lwt_result.return ()) ~f:(fun acc el ->
        let* () = acc in
        match el with
        | Run cmd ->
          action_run ~root_path:path cmd
        | Refmt globs ->
          Lwt_result.return (action_refmt ~root_path:path globs))
  in
  match t.message with
  | Some _ ->
    Logs_lwt.app (fun m -> m "%a" Pp.pp_bright_green "Done!\n") |> Lwt_result.ok
  | None ->
    Lwt_result.return ()
