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

let of_dec (dec_actions : Dec_template.Actions.t) : t =
  { message = dec_actions.message
  ; actions =
      List.map dec_actions.actions ~f:(function
          | Dec_template.Actions.Run { name; args } ->
            Run { name; args }
          | Dec_template.Actions.Refmt files ->
            Refmt files)
  }

let action_run ~root_path cmd =
  let open Lwt.Syntax in
  let f () =
    let* p_output = Spin_lwt.exec cmd.name cmd.args in
    let* () =
      Spin_lwt.fold_left p_output.stdout ~f:(fun line ->
          Logs_lwt.debug (fun m -> m "stdout of %s: %s" cmd.name line))
    in
    match p_output.status with
    | WEXITED 0 ->
      let+ () =
        Spin_lwt.fold_left p_output.stderr ~f:(fun line ->
            Logs_lwt.debug (fun m -> m "stderr of %s: %s" cmd.name line))
      in
      Ok ()
    | _ ->
      let+ () =
        Spin_lwt.fold_left p_output.stderr ~f:(fun line ->
            Logs_lwt.err (fun m -> m "stderr of %s: %s" cmd.name line))
      in
      Error
        (Spin_error.failed_to_generate
           (Printf.sprintf "The command %s did not run successfully." cmd.name))
  in
  Spin_lwt.with_chdir ~dir:root_path f

let action_refmt ~root_path globs =
  let files = Spin_sys.ls_dir root_path in
  let files =
    List.map files ~f:(fun file ->
        String.chop_prefix_exn ~prefix:root_path file)
  in
  let files = Glob.filter_files files ~globs in
  let files = List.map files ~f:(fun file -> Filename.concat root_path file) in
  List.iter files ~f:(fun input_path ->
      Logs.debug (fun m -> m "Running refmt on %s" input_path);
      Spin_refmt.convert input_path;
      Caml.Sys.remove input_path)

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
