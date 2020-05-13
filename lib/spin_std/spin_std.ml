include Base

module Result = struct
  include Base.Result

  module Let_syntax = struct
    let ( let+ ) = ( >>| )

    let ( let* ) = ( >>= )

    let ( and+ ) = Let_syntax.Let_syntax.both
  end

  let fold_left ~f l =
    List.fold_left l ~init:(Ok ()) ~f:(fun acc el ->
        bind acc ~f:(fun () -> f el))

  let fold_right ~f l =
    List.fold_right l ~init:(Ok ()) ~f:(fun el acc ->
        bind acc ~f:(fun () -> f el))
end

(* Follows Core's API but stripped everything that is POSIX only *)
module Filename = struct
  include struct
    open Caml.Filename

    let check_suffix = check_suffix

    let chop_extension = chop_extension

    let chop_suffix = chop_suffix

    let current_dir_name = current_dir_name

    let is_implicit = is_implicit

    let is_relative = is_relative

    let parent_dir_name = parent_dir_name

    let dir_sep = dir_sep

    let quote = quote

    let temp_dir_name = get_temp_dir_name ()

    let dirname = dirname

    let basename = basename
  end

  let of_parts = function
    | [] ->
      failwith "Filename.of_parts: empty parts list"
    | root :: rest ->
      List.fold rest ~init:root ~f:Caml.Filename.concat

  let concat = Caml.Filename.concat
end

module Glob = Glob

module Spin_unix = struct
  open Unix

  let mkdir ?(perm = 0o777) dirname = mkdir dirname perm

  let rec mkdir_p ?perm dir =
    let mkdir_idempotent ?perm dir =
      match mkdir ?perm dir with
      | () ->
        ()
      (* [mkdir] on MacOSX returns [EISDIR] instead of [EEXIST] if the directory
         already exists. *)
      | exception Unix_error ((EEXIST | EISDIR), _, _) ->
        ()
    in
    match mkdir_idempotent ?perm dir with
    | () ->
      ()
    | exception (Unix_error (ENOENT, _, _) as exn) ->
      let parent = Filename.dirname dir in
      if String.equal parent dir then
        raise exn
      else (
        mkdir_p ?perm parent;
        mkdir_idempotent ?perm dir)
end

module Spin_lwt = struct
  include Lwt

  let fold_left ~f l =
    List.fold_left l ~init:(Lwt.return ()) ~f:(fun acc el ->
        Lwt.bind acc (fun () -> f el))

  let fold_right ~f l =
    List.fold_right l ~init:(Lwt.return ()) ~f:(fun el acc ->
        Lwt.bind acc (fun () -> f el))

  let result_fold_left ~f l =
    List.fold_left l ~init:(Lwt_result.return ()) ~f:(fun acc el ->
        Lwt_result.bind acc (fun () -> f el))

  let result_fold_right ~f l =
    List.fold_right l ~init:(Lwt_result.return ()) ~f:(fun el acc ->
        Lwt_result.bind acc (fun () -> f el))

  type command_result =
    { stdout : string list
    ; stderr : string list
    ; status : Unix.process_status
    }

  let command_result_of_process process =
    let open Lwt.Syntax in
    let* status = process#status in
    let* stdout = Lwt_io.read_lines process#stdout |> Lwt_stream.to_list in
    let+ stderr = Lwt_io.read_lines process#stderr |> Lwt_stream.to_list in
    { stdout; stderr; status }

  let prepare_args cmd args = cmd, Array.of_list (cmd :: args)

  let exec cmd args =
    Lwt_process.with_process_full
      (prepare_args cmd args)
      command_result_of_process

  let with_chdir ~dir t =
    let open Lwt.Syntax in
    let old_cwd = Caml.Sys.getcwd () in
    let* () = Lwt_unix.chdir dir in
    Lwt.finalize t (fun () -> Lwt_unix.chdir old_cwd)
end

module Spin_sys = struct
  include Sys

  let rand_digits () =
    let rand = Random.State.(bits (make_self_init ()) land 0xFFFFFF) in
    Printf.sprintf "%06x" rand

  let mk_temp_dir ?(mode = 0o700) ?dir pat =
    let dir =
      match dir with Some d -> d | None -> Caml.Filename.get_temp_dir_name ()
    in
    let raise_err msg = raise (Sys_error msg) in
    let rec loop count =
      if count < 0 then
        raise_err "mk_temp_dir: too many failing attemps"
      else
        let dir = Printf.sprintf "%s/%s%s" dir pat (rand_digits ()) in
        try
          Unix.mkdir dir mode;
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
        | f :: fs when Caml.Sys.is_directory f ->
          Caml.Sys.readdir f
          |> Array.to_list
          |> List.map ~f:(Caml.Filename.concat f)
          |> List.append fs
          |> loop result
        | f :: fs ->
          loop (f :: result) fs
        | [] ->
          result
      in
      loop [] [ directory ] |> List.rev
    else
      Caml.Sys.readdir directory
      |> Array.to_list
      |> List.map ~f:(Caml.Filename.concat directory)
end
