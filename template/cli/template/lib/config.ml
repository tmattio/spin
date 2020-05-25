let home =
  let env_var = match Sys.os_type with "Unix" -> "HOME" | _ -> "APPDATA" in
  Sys.getenv_opt env_var |> Option.to_result ~none:({{ project_snake | capitalize }}_error.missing_env env_var)

let default_cache_dir =
  Result.map (fun home ->
      "{{ project_slug }}" |> Filename.concat ".cache" |> Filename.concat home) home

let default_config_dir =
  Result.map (fun home ->
      "{{ project_slug }}" |> Filename.concat ".config" |> Filename.concat home) home

let cache_dir =
  Sys.getenv_opt "{{ project_snake | upper }}_CACHE_DIR"
  |> Option.map Result.ok
  |> Option.value ~default:default_cache_dir

let config_dir =
  Sys.getenv_opt "{{ project_snake | upper }}_CONFIG_DIR"
  |> Option.map Result.ok
  |> Option.value ~default:default_config_dir
