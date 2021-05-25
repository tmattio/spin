include Stdlib.Sys

let mkdir ?(perm = 0o755) dirname = Unix.mkdir dirname perm

let rec mkdir_p ?perm dir =
  match dir with
  | "." | ".." ->
    ()
  | _ ->
    let mkdir_idempotent ?(perm = 0o755) dir =
      match Unix.mkdir dir perm with
      | () ->
        ()
      (* [mkdir] on MacOSX returns [EISDIR] instead of [EEXIST] if the directory
         already exists. *)
      | (exception Unix.Unix_error ((EEXIST | EISDIR), _, _))
      | (exception Sys_error _) ->
        ()
    in
    (match mkdir_idempotent ?perm dir with
    | () ->
      ()
    | exception (Unix.Unix_error (ENOENT, _, _) as exn) ->
      let parent = Filename.dirname dir in
      if String.equal parent dir then
        raise exn
      else (
        mkdir_p ?perm parent;
        mkdir_idempotent ?perm dir))

let rec rm_p path =
  match is_directory path with
  | true ->
    readdir path |> Array.iter (fun name -> rm_p (Filename.concat path name));
    Unix.rmdir path
  | false ->
    remove path

let rand_digits () =
  let rand = Random.State.(bits (make_self_init ()) land 0xFFFFFF) in
  Printf.sprintf "%06x" rand

let mk_temp_dir ?(mode = 0o700) ?dir pat =
  let dir = match dir with Some d -> d | None -> Filename.temp_dir_name in
  let raise_err msg = raise (Sys_error msg) in
  let rec loop count =
    if count < 0 then
      raise_err "mk_temp_dir: too many failing attemps"
    else
      let dir = Printf.sprintf "%s/%s%s" dir pat (rand_digits ()) in
      try
        mkdir dir ~perm:mode;
        dir
      with
      | Unix.Unix_error (Unix.EEXIST, _, _) ->
        loop (count - 1)
      | Unix.Unix_error (Unix.EINTR, _, _) ->
        loop count
      | Unix.Unix_error (e, _, _) ->
        raise_err ("mk_temp_dir: " ^ Unix.error_message e)
  in
  loop 1000

let ls_dir ?(recursive = true) directory =
  if recursive then
    let rec loop result = function
      | f :: fs when is_directory f ->
        readdir f
        |> Array.to_list
        |> List.map (Filename.concat f)
        |> List.append fs
        |> loop result
      | f :: fs ->
        loop (f :: result) fs
      | [] ->
        result
    in
    loop [] [ directory ] |> List.rev
  else
    readdir directory |> Array.to_list |> List.map (Filename.concat directory)

let with_chdir dir f =
  let old_cwd = getcwd () in
  Unix.chdir dir;
  let result = f () in
  Unix.chdir old_cwd;
  result

let write_file file content =
  let oc = open_out file in
  Printf.fprintf oc "%s" content;
  close_out oc

let read_lines file : string list =
  let ic = open_in file in
  let try_read () = try Some (input_line ic) with End_of_file -> None in
  let rec loop acc =
    match try_read () with
    | Some s ->
      loop (s :: acc)
    | None ->
      close_in ic;
      List.rev acc
  in
  loop []

let read_file file = String.concat "\n" (read_lines file)
