type t = [ `Missing_env_var of string ]

let to_string = function
  | `Missing_env_var s ->
    Printf.sprintf
      "The environment variable %S is needed, but could not be found in \
       your environment.\n\
       Hint: Try setting it and run the program again."
      s

let missing_env env = `Missing_env_var env
