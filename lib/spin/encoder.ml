type 'a t = 'a -> Sexp.t

let string = Sexplib.Conv.sexp_of_string

let int = Sexplib.Conv.sexp_of_int

let float = Sexplib.Conv.sexp_of_float

let bool = Sexplib.Conv.sexp_of_bool

let null = Sexplib.Conv.sexp_of_unit ()

let nullable encoder = function None -> null | Some x -> encoder x

let list encoder xs = Sexplib.Conv.sexp_of_list (fun x -> encoder x) xs

let obj xs =
  Sexp.List (List.map xs ~f:(fun (k, v) -> Sexp.List [ string k; v ]))

let encode_sexp ~f x = f x

let encode_string ~f x = f x |> Sexplib.Sexp.to_string_hum ~indent:1

let encode_sexps_string ~f x =
  match f x with
  | Sexp.Atom _ as sexp ->
    Sexplib.Sexp.to_string_hum sexp ~indent:1
  | Sexp.List sexps ->
    List.map sexps ~f:(Sexplib.Sexp.to_string_hum ~indent:1)
    |> String.concat ~sep:"\n\n"

let encode_file ~f ~path x =
  match f x with
  | Sexp.Atom _ as sexp ->
    Sexplib.Sexp.save_hum path sexp
  | Sexp.List sexps ->
    Sexplib.Sexp.save_sexps_hum path sexps
