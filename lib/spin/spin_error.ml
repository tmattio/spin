type t =
  [ `Missing_env_var of string
  | `Failed_to_parse of string * string
  | `Invalid_template of string * string
  | `Failed_to_generate of string
  | `Generator_error of string * string
  ]

let to_string = function
  | `Missing_env_var s ->
    Printf.sprintf
      "The environment variable \"%s\" is needed, but could not be found in \
       your environment.\n\n\
       Hint: Try setting it and run the program again."
      s
  | `Failed_to_parse (file, reason) ->
    Printf.sprintf
      "I failed to parse the file %S:\n\
       %s\n\n\
       Hint: If you think this is a bug, open an issue on the owner's \
       repository."
      file
      reason
  | `Invalid_template (template, reason) ->
    Printf.sprintf
      "%s is not a valid spin template:\n\
       %s\n\n\
       Hint: If you think this is a bug, open an issue on the owner's \
       repository."
      template
      reason
  | `Missing_template_context var ->
    Printf.sprintf
      "Missing context variable to generate the project:\n\
       %s\n\n\
       Hint: This is most likely an error in the template definition. You \
       should probably open an issue on the owner's repository"
      var
  | `Failed_to_generate msg ->
    Printf.sprintf "The template generation failed:\n%s" msg
  | `Generator_error (generator, reason) ->
    Printf.sprintf "Failed to run the generator %S:\n%s" generator reason

let missing_env env = `Missing_env_var env

let failed_to_parse ~msg file = `Failed_to_parse (file, msg)

let failed_to_generate msg = `Failed_to_generate msg

let invalid_template ~msg template = `Invalid_template (template, msg)

let generator_error ~msg generator = `Generator_error (generator, msg)

let of_decoder_error ~file e =
  let msg = Decoder.string_of_error e in
  failed_to_parse file ~msg

let sexp_of_t t =
  let open Sexplib.Sexp in
  match t with
  | `Missing_env_var e ->
    List [ Atom "Missing_env_var"; Atom e ]
  | `Failed_to_parse (e1, e2) ->
    List [ Atom "Missing_env_var"; Atom e1; Atom e2 ]
  | `Invalid_template (e1, e2) ->
    List [ Atom "Missing_env_var"; Atom e1; Atom e2 ]
  | `Failed_to_generate e ->
    List [ Atom "Failed_to_generate"; Atom e ]
  | `Generator_error (e1, e2) ->
    List [ Atom "Missing_env_var"; Atom e1; Atom e2 ]

let pp fmt t = Sexplib.Sexp.pp_hum fmt (sexp_of_t t)
