let home =
  let env_var = match Sys.os_type with "Unix" -> "HOME" | _ -> "APPDATA" in
  Sys.getenv env_var |> Result.of_option ~error:(`Missing_env_var env_var)

let default_cache_dir =
  Result.map home ~f:(fun home -> Filename.of_parts [ home; ".cache"; "spin" ])

let default_config_dir =
  Result.map home ~f:(fun home -> Filename.of_parts [ home; ".config"; "spin" ])

let spin_cache_dir =
  Sys.getenv "SPIN_CACHE_DIR"
  |> Option.map ~f:Result.return
  |> Option.value ~default:default_cache_dir

let spin_config_dir =
  Sys.getenv "SPIN_CONFIG_DIR"
  |> Option.map ~f:Result.return
  |> Option.value ~default:default_config_dir
