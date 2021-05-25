module Make_valid_string (M : sig
  val err : string

  val regex : string
end) =
struct
  module Errors = struct
    let invalid_value = M.err
  end

  type t = string

  let decode = Decoder.string_matching ~regex:M.regex ~err:Errors.invalid_value

  let encode = Encoder.string
end

module Template_name = Make_valid_string (struct
  let err =
    "The name of the template must contain only alphanumeric characters \
     separated by \"-\" or \"_\"."

  let regex = {|^[a-z0-9]+\([_-][a-z0-9]+\)*$|}
end)

module Git_repo = Make_valid_string (struct
  let err = "The repository must be a valid git URI."

  let regex =
    {|^\(\(git\|ssh\|http\(s\)?\)\|\(git@[a-zA-Z0-9_\.-]+\)\)\(:\(//\)?\)\([[a-zA-Z0-9_\.@:/~-]+\)\(\.git\)\(/\)?$|}
end)

module Source = struct
  type t =
    | Git of string
    | Local_dir of string
    | Official of string

  let decode =
    let open Decoder in
    one_of
      [ ( "official"
        , let+ v = field "official" Template_name.decode in
          Official v )
      ; ( "local"
        , let+ v = field "local" string in
          Local_dir v )
      ; ( "git"
        , let+ v = field "git" Git_repo.decode in
          Local_dir v )
      ]

  let encode = function
    | Git v ->
      Sexplib.Sexp.List [ Sexplib.Sexp.Atom "git"; Sexplib.Sexp.Atom v ]
    | Local_dir v ->
      Sexplib.Sexp.List [ Sexplib.Sexp.Atom "local"; Sexplib.Sexp.Atom v ]
    | Official v ->
      Sexplib.Sexp.List [ Sexplib.Sexp.Atom "official"; Sexplib.Sexp.Atom v ]
end
