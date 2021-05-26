let default_cache_dir =
  match Sys.os_type with
  | "Unix" ->
    Sys.getenv_opt "HOME"
    |> Option.to_result ~none:(`Missing_env_var "HOME")
    |> Result.map (fun home -> Filename.of_parts [ home; ".cache"; "spin" ])
  | _ ->
    Sys.getenv_opt "APPDATA"
    |> Option.to_result ~none:(`Missing_env_var "APPDATA")
    |> Result.map (fun home -> Filename.of_parts [ home; "spin"; "cache" ])

let default_config_dir =
  match Sys.os_type with
  | "Unix" ->
    Sys.getenv_opt "HOME"
    |> Option.to_result ~none:(`Missing_env_var "HOME")
    |> Result.map (fun home -> Filename.of_parts [ home; ".config"; "spin" ])
  | _ ->
    Sys.getenv_opt "APPDATA"
    |> Option.to_result ~none:(`Missing_env_var "APPDATA")
    |> Result.map (fun home -> Filename.of_parts [ home; "spin"; "config" ])

let spin_cache_dir =
  Sys.getenv_opt "SPIN_CACHE_DIR"
  |> Option.map Result.ok
  |> Option.value ~default:default_cache_dir

let spin_config_dir =
  Sys.getenv_opt "SPIN_CONFIG_DIR"
  |> Option.map Result.ok
  |> Option.value ~default:default_config_dir

let verbose () = match Logs.level () with Some Logs.Debug -> true | _ -> false
