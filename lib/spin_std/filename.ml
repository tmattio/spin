open Stdlib.Filename

let check_suffix = check_suffix

let chop_extension = chop_extension

let chop_suffix = chop_suffix

let current_dir_name = current_dir_name

let is_implicit = is_implicit

let is_relative = is_relative

let parent_dir_name = parent_dir_name

let dir_sep = dir_sep

let quote = quote

let temp_dir_name = get_temp_dir_name ()

let dirname = dirname

let basename = basename

let of_parts = function
  | [] ->
    failwith "Filename.of_parts: empty parts list"
  | root :: rest ->
    List.fold_left concat root rest

let concat = concat
