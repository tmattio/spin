let repo_regex =
  {|^\(\(git\|ssh\|http\(s\)?\)\|\(git@[a-zA-Z0-9_\.-]+\)\)\(:\(//\)?\)\([[a-zA-Z0-9_\.@:/~-]+\)\(\.git\)\(/\)?$|}

let cache_dir_of_repo repo =
  let regexp = Str.regexp repo_regex in
  if Str.string_match regexp repo 0 then
    let open Result.Syntax in
    let repo_name = Str.matched_group 7 repo in
    let+ cache_dir = Config.spin_cache_dir in
    Filename.of_parts [ cache_dir; repo_name ]
  else
    Error
      (Spin_error.invalid_template
         repo
         ~msg:"The Git repo URI could not be parsed.")

let git_clone ~destination repo =
  let open Result.Syntax in
  Logs.app (fun m -> m "📡  Downloading %a to %s" Pp.pp_blue repo destination);
  Logs.debug (fun m -> m "Cloning %S to %S" repo destination);
  let+ () =
    Spawn.exec "git" [ "clone"; repo; destination ]
    |> Result.map_error (fun err ->
           let msg =
             Printf.sprintf "The repository could not be downloaded: %s" err
           in
           Spin_error.invalid_template repo ~msg)
  in
  Logs.app (fun m -> m "%a" Pp.pp_bright_green "Done!\n")

let donwload_git_repo repo =
  let open Result.Syntax in
  let* cache_dir = cache_dir_of_repo repo in
  let+ () =
    if Sys.file_exists cache_dir && Sys.is_directory cache_dir then (
      Logs.app (fun m ->
          m "The repository %a has already been downloaded." Pp.pp_blue repo);
      let refetch =
        Inquire.confirm "Do you want to download it again?" ~default:true
      in
      if refetch then (
        Logs.debug (fun m -> m "Removing %S" cache_dir);
        Sys.rm_p cache_dir;
        git_clone repo ~destination:cache_dir)
      else
        Result.ok ())
    else (
      Sys.mkdir_p cache_dir;
      git_clone repo ~destination:cache_dir)
  in
  cache_dir
