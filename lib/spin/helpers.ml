let slugify value =
  value
  |> Str.global_replace (Str.regexp " ") "-"
  |> String.lowercase
  |> Str.global_replace (Str.regexp "[^a-z0-9\\-]") ""

let modulify value =
  value
  |> String.substr_replace_all ~pattern:"-" ~with_:"_"
  |> String.substr_replace_all ~pattern:" " ~with_:"_"
  |> String.capitalize

let snake_case value =
  value
  |> String.substr_replace_all ~pattern:"-" ~with_:"_"
  |> String.substr_replace_all ~pattern:" " ~with_:"_"
  |> Str.global_replace (Str.regexp "\\([^_A-Z]\\)\\([A-Z]\\)") "\\1_\\2"
  |> String.lowercase

let camel_case value =
  value
  |> Str.global_substitute
       (Str.regexp "^\\([a-z]\\)\\|[_\\-]\\([a-z]\\)")
       (fun s -> String.uppercase (Str.matched_string s))
  |> Str.global_replace (Str.regexp "[_\\-]") ""
