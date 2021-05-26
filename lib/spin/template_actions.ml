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

let command_to_string = function
  | { name; args = [] } ->
    name
  | { name; args } ->
    Printf.sprintf "%s %s" name (String.concat " " args)

let of_dec ~context (dec_actions : Dec_template.Actions.t) =
  let message =
    match dec_actions.message with
    | Some message ->
      let evaluated = Template_expr.eval message ~context in
      Some evaluated
    | None ->
      None
  in
  let actions =
    List.map
      (function
        | Dec_template.Actions.Run { name; args } ->
          Run { name; args }
        | Dec_template.Actions.Refmt files ->
          let files = List.map (Template_expr.eval ~context) files in
          Refmt files)
      dec_actions.actions
  in
  { message; actions }

let action_run ~root_path cmd =
  Logs.debug (fun m -> m "Running %s" (command_to_string cmd));
  Spawn.exec cmd.name cmd.args ~cwd:(Path root_path)
  |> Result.map_error (fun err ->
         Spin_error.failed_to_generate
           (Printf.sprintf
              "The command %s did not run successfully: %s"
              (command_to_string cmd)
              err))

let action_refmt ~root_path globs =
  let open Result.Syntax in
  let files = Sys.ls_dir root_path in
  Result.List.iter
    (fun input_path ->
      let normalized_path =
        input_path
        |> Fpath.v
        |> (fun p -> Option.get (Fpath.rem_prefix (Fpath.v root_path) p))
        |> Fpath.to_string
        |> Str.global_replace (Str.regexp "\\\\") "/"
      in
      if Glob.matches_globs normalized_path ~globs then
        let () = Logs.debug (fun m -> m "Running refmt on %s" input_path) in
        let+ () = Refmt.convert ~project_root:root_path normalized_path in
        Sys.remove input_path
      else
        Ok ())
    files

let run ~path t =
  let open Result.Syntax in
  Option.iter (fun msg -> Logs.app (fun m -> m "%s" msg)) t.message;
  let+ () =
    Result.List.fold_left
      (fun _ el ->
        match el with
        | Run cmd ->
          action_run ~root_path:path cmd
        | Refmt globs ->
          action_refmt ~root_path:path globs)
      ()
      t.actions
  in
  Option.iter
    (fun _msg -> Logs.app (fun m -> m "%a" Pp.pp_bright_green "Done!\n"))
    t.message

let of_decs_with_condition ~context l =
  Template_expr.filter_map
    ~context
    ~condition:(fun el -> el.Dec_template.Actions.enabled_if)
    (of_dec ~context)
    l
