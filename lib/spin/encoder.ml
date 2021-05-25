open Sexplib0

type 'a t = 'a -> Sexp.t

let string = Sexp_conv.sexp_of_string

let int = Sexp_conv.sexp_of_int

let float = Sexp_conv.sexp_of_float

let bool = Sexp_conv.sexp_of_bool

let null = Sexp_conv.sexp_of_unit ()

let nullable encoder = function None -> null | Some x -> encoder x

let list encoder xs = Sexp_conv.sexp_of_list (fun x -> encoder x) xs

let obj xs = Sexp.List (List.map (fun (k, v) -> Sexp.List [ string k; v ]) xs)

let encode_sexp x f = f x

let encode_string x f = f x |> Sexp.to_string_hum ~indent:1

let encode_sexps_string x f =
  match f x with
  | Sexp.Atom _ as sexp ->
    Sexp.to_string_hum sexp ~indent:1
  | Sexp.List sexps ->
    List.map (Sexp.to_string_hum ~indent:1) sexps |> String.concat "\n\n"

let encode_file path x f =
  match f x with
  | Sexp.Atom _ as sexp ->
    Sexplib.Sexp.save_hum path sexp
  | Sexp.List sexps ->
    Sexplib.Sexp.save_sexps_hum path sexps
