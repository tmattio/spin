let run ~cwd ~stdout cmd args =
  Logs.debug (fun m -> m "Running \"%s %s\"" cmd (String.concat " " args));
  Spawn.exec cmd args ~stdout ~cwd:(Path cwd)
  |> Result.map_error (fun err ->
         let msg =
           Printf.sprintf
             "an error occured while running \"%s %s\": %s"
             cmd
             (String.concat " " args)
             err
         in
         Spin_error.failed_to_generate msg)

let is_esy_project project_root =
  Sys.file_exists (Filename.concat project_root "esy.json")

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
  match get_refmt_command filename with
  | Some (command, output_filename) ->
    let oc = open_out (Filename.concat project_root output_filename) in
    let res =
      run ~cwd:project_root ~stdout:(Unix.descr_of_out_channel oc) "esy" command
    in
    close_out oc;
    res
  | None ->
    Ok ()

let convert_with_opam ~project_root filename =
  match get_refmt_command filename with
  | Some (command, output_filename) ->
    let oc = open_out (Filename.concat project_root output_filename) in
    let res =
      run
        ~cwd:project_root
        ~stdout:(Unix.descr_of_out_channel oc)
        "opam"
        ([ "exec"; "--" ] @ command)
    in
    close_out oc;
    res
  | None ->
    Ok ()

let convert ~project_root file =
  if is_esy_project project_root then
    convert_with_esy ~project_root file
  else
    convert_with_opam ~project_root file
