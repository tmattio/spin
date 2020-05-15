let default_cache_dir =
  match Sys.os_type with 
  | "Unix" -> 
    Sys.getenv "HOME" 
    |> Result.of_option ~error:(`Missing_env_var "HOME")
    |> Result.map ~f:(fun home -> Filename.of_parts [ home; ".cache"; "spin" ])
  | _ -> 
    Sys.getenv "APPDATA"
    |> Result.of_option ~error:(`Missing_env_var "APPDATA")
    |> Result.map ~f:(fun home -> Filename.of_parts [ home; "spin"; "cache" ])

let default_config_dir =
  match Sys.os_type with 
  | "Unix" -> 
    Sys.getenv "HOME" 
    |> Result.of_option ~error:(`Missing_env_var "HOME")
    |> Result.map ~f:(fun home -> Filename.of_parts [ home; ".config"; "spin" ])
  | _ -> 
    Sys.getenv "APPDATA"
    |> Result.of_option ~error:(`Missing_env_var "APPDATA")
    |> Result.map ~f:(fun home -> Filename.of_parts [ home; "spin"; "config" ])

let spin_cache_dir =
  Sys.getenv "SPIN_CACHE_DIR"
  |> Option.map ~f:Result.return
  |> Option.value ~default:default_cache_dir

let spin_config_dir =
  Sys.getenv "SPIN_CONFIG_DIR"
  |> Option.map ~f:Result.return  
  |> Option.value ~default:default_config_dir
