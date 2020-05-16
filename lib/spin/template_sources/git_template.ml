let repo_regex =
  {|^\(\(git\|ssh\|http\(s\)?\)\|\(git@[a-zA-Z0-9_\.-]+\)\)\(:\(//\)?\)\([[a-zA-Z0-9_\.@:/~-]+\)\(\.git\)\(/\)?$|}

let cache_dir_of_name name =
  let open Result.Let_syntax in
  let+ cache_dir = Config.spin_cache_dir in
  Filename.of_parts [ cache_dir; name ]

let git_clone ~destination repo =
  let open Lwt_result.Syntax in
  let* () =
    Logs_lwt.app (fun m ->
        m "📡  Downloading %a to %s" Pp.pp_blue repo destination)
    |> Lwt_result.ok
  in
  let* () =
    Logs_lwt.debug (fun m -> m "Cloning %S to %S" repo destination)
    |> Lwt_result.ok
  in
  let* () =
    Spin_lwt.exec_with_logs "git" [ "clone"; repo; destination ]
    |> Lwt_result.map_err (fun _ ->
           Spin_error.invalid_template
             repo
             ~msg:"The repository could not be downloaded.")
  in
  Logs_lwt.app (fun m -> m "%a" Pp.pp_bright_green "Done!\n") |> Lwt_result.ok

let donwload_git_repo repo =
  let regexp = Str.regexp repo_regex in
  if Str.string_match regexp repo 0 then
    let open Lwt_result.Syntax in
    let repo_name = Str.matched_group 7 repo in
    let* cache_dir = cache_dir_of_name repo_name |> Lwt.return in
    let+ () =
      if Caml.Sys.file_exists cache_dir && Caml.Sys.is_directory cache_dir then
        let* () =
          Logs_lwt.app (fun m ->
              m
                "The repository %a has already been downloaded."
                Pp.pp_blue
                repo_name)
          |> Lwt_result.ok
        in
        let* refetch =
          Inquire.confirm "Do you want to download it again?" ~default:true
          |> Lwt_result.ok
        in
        if refetch then (
          let* () =
            Logs_lwt.debug (fun m -> m "Removing %S" cache_dir) |> Lwt_result.ok
          in
          Spin_unix.rm_p cache_dir;
          git_clone repo ~destination:cache_dir)
        else
          Lwt_result.return ()
      else (
        Spin_unix.mkdir_p cache_dir;
        git_clone repo ~destination:cache_dir)
    in
    cache_dir
  else
    Lwt.return
      (Error
         (Spin_error.invalid_template
            repo
            ~msg:"The Git repo URI could not be parsed."))
