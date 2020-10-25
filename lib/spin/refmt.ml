let run ~root_path cmd args =
  let open Lwt.Syntax in
  let* () =
    Logs_lwt.debug (fun m ->
        m "Running %s %s" cmd (String.concat args ~sep:" "))
  in
  Spin_lwt.with_chdir ~dir:root_path (fun () ->
      Spin_lwt.exec_with_stdout cmd args)

let is_esy_project project_root =
  Caml.Sys.file_exists (Filename.concat project_root "esy.json")

let get_refmt_command filename =
  if Filename.check_suffix filename ".ml" then
    Some
      ( [ "refmt"; filename; "--interface=false"; "--parse=ml"; "--print=re" ]
      , Filename.chop_suffix filename ".ml" ^ ".re" )
  else if Filename.check_suffix filename ".mli" then
    Some
      ( [ "refmt"; filename; "--interface=true"; "--parse=ml"; "--print=re" ]
      , Filename.chop_suffix filename ".mli" ^ ".rei" )
  else if Filename.check_suffix filename ".re" then
    Some
      ( [ "refmt"; filename; "--interface=false"; "--parse=re"; "--print=ml" ]
      , Filename.chop_suffix filename ".re" ^ ".ml" )
  else if Filename.check_suffix filename ".rei" then
    Some
      ( [ "refmt"; filename; "--interface=true"; "--parse=re"; "--print=ml" ]
      , Filename.chop_suffix filename ".rei" ^ ".mli" )
  else
    None

let convert_with_esy ~project_root filename =
  let open Lwt_result.Syntax in
  match get_refmt_command filename with
  | Some (command, output_filename) ->
    let* stdout = run ~root_path:project_root "esy" command in
    Lwt_io.with_file
      (Filename.concat project_root output_filename)
      (fun oc -> Lwt_io.write oc stdout |> Lwt_result.ok)
      ~mode:Lwt_io.Output
  | None ->
    Lwt.return_ok ()

let convert_with_opam ~project_root filename =
  let open Lwt_result.Syntax in
  match get_refmt_command filename with
  | Some (command, output_filename) ->
    let* stdout =
      run ~root_path:project_root "opam" ([ "exec"; "--" ] @ command)
    in
    Lwt_io.with_file
      (Filename.concat project_root output_filename)
      (fun oc -> Lwt_io.write oc stdout |> Lwt_result.ok)
      ~mode:Lwt_io.Output
  | None ->
    Lwt.return_ok ()

let convert ~project_root file =
  if is_esy_project project_root then
    convert_with_esy ~project_root file
  else
    convert_with_opam ~project_root file
