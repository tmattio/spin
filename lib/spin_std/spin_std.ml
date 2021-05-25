module Glob = Glob
module Hashtbl = Hashtbl
module List = List
module Result = Result
module String = String
module Filename = Filename
module Sys = Sys

module Spawn = struct
  include Spawn

  let resolve_in_path prog =
    (* Do not try to resolve in the path if the program is something like
     * ./this.exe *)
    if String.split_on_char '/' prog |> List.length <> 1 then
      Some prog
    else
      let paths = Sys.getenv "PATH" |> String.split_on_char ':' in
      List.map (fun d -> Filename.concat d prog) paths
      |> List.find_opt Sys.file_exists

  let resolve_in_path_exn prog =
    match resolve_in_path prog with
    | None ->
      failwith (Printf.sprintf "no program in path %s" prog)
    | Some prog ->
      prog

  let spawn ?env ?cwd ?stdin ?stdout ?stderr prog argv =
    let prog = resolve_in_path_exn prog in
    let argv = prog :: argv in
    spawn ~prog ~argv ?env ?cwd ?stdin ?stdout ?stderr ()

  let exec ?env ?cwd ?stdin ?stdout ?stderr prog argv =
    let pid = spawn ?env ?cwd ?stdin ?stdout ?stderr prog argv in
    match snd (Unix.waitpid [] pid) with
    | WEXITED 0 ->
      Ok ()
    | WEXITED n ->
      Error (Printf.sprintf "exited with code %d" n)
    | WSIGNALED n ->
      Error (Printf.sprintf "exited with signal %d" n)
    | WSTOPPED n ->
      Error (Printf.sprintf "stopped with code %d" n)
end
