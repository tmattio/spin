open Jingoo;

let slugify = value => {
  value
  |> Str.global_replace(Str.regexp(" "), "-")
  |> String.lowercase
  |> Str.global_replace(Str.regexp("[^a-z0-9\\-]"), "");
};

let modulify = value => {
  value
  |> Str.global_replace(Str.regexp(" "), "_")
  |> Str.global_replace(Str.regexp("-"), "_")
  |> String.uppercase;
};

let snake_case = value =>
  value
  |> Str.global_replace(Str.regexp("\\([^_A-Z]\\)\\([A-Z]\\)"), "\\1_\\2")
  |> String.lowercase;

let camel_case = value => {
  value
  |> Str.global_substitute(Str.regexp("^\\([a-z]\\)\\|[_-]\\([a-z]\\)"), s =>
       String.uppercase(Str.matched_string(s))
     )
  |> Str.global_replace(Str.regexp("[_-]"), "");
};

let jg_string_fn = (~kwargs=?, ~defaults=?, fn, value) => {
  let value = Jg_runtime.string_of_tvalue(value);
  let slug = fn(value);
  Jg_types.Tstr(slug);
};

let filters = [
  ("slugify", slugify |> jg_string_fn |> Jg_types.func_arg1_no_kw),
  ("modulify", modulify |> jg_string_fn |> Jg_types.func_arg1_no_kw),
  ("snake_case", snake_case |> jg_string_fn |> Jg_types.func_arg1_no_kw),
  ("camel_case", camel_case |> jg_string_fn |> Jg_types.func_arg1_no_kw),
];
