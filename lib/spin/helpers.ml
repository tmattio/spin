let slugify value =
  value
  |> Str.global_replace (Str.regexp " ") "-"
  |> String.lowercase_ascii
  |> Str.global_replace (Str.regexp "[^a-z0-9\\-]") ""

let snake_case value =
  value
  |> Str.global_replace (Str.regexp "-") "_"
  |> Str.global_replace (Str.regexp " ") "_"
  |> Str.global_replace (Str.regexp "\\([^_A-Z]\\)\\([A-Z]\\)") "\\1_\\2"
  |> String.lowercase_ascii

let camel_case value =
  value
  |> Str.global_substitute
       (Str.regexp "^\\([a-z]\\)\\|[_\\-]\\([a-z]\\)")
       (fun s -> String.uppercase_ascii (Str.matched_string s))
  |> Str.global_replace (Str.regexp "[_\\-]") ""
