(* This module is heavily inspired by
   https://github.com/mattjbray/ocaml-decoders/ *)

type error =
  | Decoder_error of string * Sexp.t option
  | Decoder_errors of error list
  | Decoder_tag of string * error

type 'a t = Sexp.t -> ('a, error) Result.t

(* Error handling *)

let pp_sexp fmt value = Caml.Format.fprintf fmt "@[%a@]" Sexp.pp_hum value

let rec pp_error fmt = function
  | Decoder_error (msg, Some t) ->
    Caml.Format.fprintf fmt "@[%s, but got@ @[%a@]@]" msg pp_sexp t
  | Decoder_error (msg, None) ->
    Caml.Format.fprintf fmt "@[%s@]" msg
  | Decoder_errors errors ->
    Caml.Format.fprintf
      fmt
      "@[%a@]"
      (Caml.Format.pp_print_list ~pp_sep:Caml.Format.pp_print_space pp_error)
      errors
  | Decoder_tag (msg, error) ->
    Caml.Format.fprintf fmt "@[<2>%s:@ @[%a@]@]" msg pp_error error

let string_of_error error = Caml.Format.asprintf "@[<2>%a@?@]" pp_error error

let merge_errors e1 e2 =
  match e1, e2 with
  | Decoder_errors e1s, Decoder_errors e2s ->
    Decoder_errors (e1s @ e2s)
  | Decoder_errors e1s, _ ->
    Decoder_errors (e1s @ [ e2 ])
  | _, Decoder_errors e2s ->
    Decoder_errors ([ e1 ] @ e2s)
  | _ ->
    Decoder_errors [ e1; e2 ]

let combine_errors results =
  let rec aux combined = function
    | [] ->
      (match combined with
      | Ok xs ->
        Ok (List.rev xs)
      | Error es ->
        Error (List.rev es))
    | result :: rest ->
      let combined =
        match result, combined with
        | Ok x, Ok xs ->
          Ok (x :: xs)
        | Error e, Error es ->
          Error (e :: es)
        | Error e, Ok _ ->
          Error [ e ]
        | Ok _, Error es ->
          Error es
      in
      aux combined rest
  in
  aux (Ok []) results

let decoder_error ~msg sexp = Decoder_error (msg, Some sexp)

let tag_error ~msg error = Decoder_tag (msg, error)

let tag_errors ~msg errors = Decoder_tag (msg, Decoder_errors errors)

(* Loading s-expressions *)

let of_string s =
  let result =
    try Ok (Sexplib.Sexp.of_string s) with Failure msg -> Error msg
  in
  Result.map_error result ~f:(fun msg ->
      Decoder_tag ("S-Expression parsing error", Decoder_error (msg, None)))

let of_sexps_string (s : string) =
  let s = "(" ^ s ^ ")" in
  of_string s

let of_file s =
  let result =
    try Ok (Sexplib.Sexp.load_sexp s) with e -> Error (Exn.to_string e)
  in
  Result.map_error result ~f:(fun msg ->
      Decoder_tag
        ( Printf.sprintf "S-Expression parsing error while reading %S" s
        , Decoder_error (msg, None) ))

let of_sexps_file s =
  let result =
    try Ok (Sexp.List (Sexplib.Sexp.load_sexps s)) with
    | e ->
      Error (Exn.to_string e)
  in
  Result.map_error result ~f:(fun msg ->
      Decoder_tag
        ( Printf.sprintf "S-Expression parsing error while reading %S" s
        , Decoder_error (msg, None) ))

(* Decoding primitives *)

let decode_primitive ~f ~err = function
  | Sexp.Atom _ as sexp ->
    (try Ok (f sexp) with
    | Sexplib.Conv.Of_sexp_error _ ->
      Error (decoder_error ~msg:err sexp))
  | sexp ->
    Error (decoder_error ~msg:"Expected a single value" sexp)

let string =
  decode_primitive ~f:Sexplib.Conv.string_of_sexp ~err:"Expected a string"

let int = decode_primitive ~f:Sexplib.Conv.int_of_sexp ~err:"Expected an int"

let float =
  decode_primitive ~f:Sexplib.Conv.float_of_sexp ~err:"Expected a float"

let bool = decode_primitive ~f:Sexplib.Conv.bool_of_sexp ~err:"Expected a bool"

let null = decode_primitive ~f:Sexplib.Conv.unit_of_sexp ~err:"Expected a unit"

(* Helpers *)

let string_matching ~regex ~err sexp =
  let validate_format s =
    let regexp = Str.regexp regex in
    Str.string_match regexp s 0
  in
  match sexp with
  | Sexp.Atom atom ->
    if validate_format atom then
      Ok atom
    else
      Error
        (decoder_error
           sexp
           ~msg:(Printf.sprintf "Invalid value %S. %s" atom err))
  | sexp ->
    Error (decoder_error sexp ~msg:"Expected a single value")

(* Decoding lists *)

let list decoder sexp =
  match sexp with
  | Sexp.Atom _ ->
    Error (decoder_error ~msg:"Expected a list" sexp)
  | Sexp.List sexps ->
    List.mapi sexps ~f:(fun i x ->
        decoder x
        |> Result.map_error ~f:(fun error ->
               tag_error ~msg:(Printf.sprintf "element %i" i) error))
    |> combine_errors
    |> Result.map_error ~f:(fun errors ->
           tag_errors ~msg:"while decoding a list" errors)

(* Decoding records *)

let key_value_pairs = function
  | Sexp.List l ->
    let kv_pairs_opt =
      List.map l ~f:(function
          | Sexp.List [ key; value ] ->
            Some (key, value)
          | Sexp.List (key :: values) ->
            Some (key, Sexp.List values)
          | _ ->
            None)
    in
    let all_some l =
      try
        Some (List.map l ~f:(function Some x -> x | None -> raise Caml.Exit))
      with
      | Caml.Exit ->
        None
    in
    all_some kv_pairs_opt
  | _ ->
    None

let field_opt ~f key sexp =
  let value =
    match sexp with
    | Sexp.List [ Sexp.Atom s; value ] when String.equal s key ->
      Some value
    | Sexp.List (Sexp.Atom s :: values) when String.equal s key ->
      Some (Sexp.List values)
    | _ ->
      (match key_value_pairs sexp with
      | Some kv_pairs ->
        List.find_map kv_pairs ~f:(fun (k, v) ->
            match string k with
            | Ok s when String.equal s key ->
              Some v
            | _ ->
              None)
      | _ ->
        None)
  in
  match value with
  | Some value ->
    f value
    |> Result.map ~f:Option.return
    |> Result.map_error ~f:(fun error ->
           tag_error ~msg:(Printf.sprintf "Error in field %S" key) error)
  | None ->
    Ok None

let field ~f key sexp =
  match field_opt ~f key sexp with
  | Ok None ->
    Error
      (decoder_error
         ~msg:(Printf.sprintf "Expected an s-expression with a field %S" key)
         sexp)
  | Ok (Some v) ->
    Ok v
  | Error e ->
    Error e

let fields ~f key sexp =
  let values =
    match sexp with
    | Sexp.List [ Sexp.Atom s; value ] when String.equal s key ->
      [ value ]
    | Sexp.List (Sexp.Atom s :: values) when String.equal s key ->
      [ Sexp.List values ]
    | _ ->
      (match key_value_pairs sexp with
      | Some kv_pairs ->
        List.fold_left kv_pairs ~init:[] ~f:(fun acc (k, v) ->
            match string k with
            | Ok s when String.equal s key ->
              v :: acc
            | _ ->
              acc)
      | _ ->
        [])
  in
  let rec aux acc = function
    | [] ->
      Ok acc
    | el :: rest ->
      (match f el with
      | Ok v ->
        aux (v :: acc) rest
      | Error e ->
        Error (tag_error ~msg:(Printf.sprintf "Error in field %S" key) e))
  in
  aux [] values

(* Inconsistent structure *)

let one_of_opt decoders sexp =
  let rec go = function
    | (_, decoder) :: rest ->
      (match decoder sexp with
      | Ok result ->
        Ok (Some result)
      | Error _ ->
        go rest)
    | [] ->
      Ok None
  in
  go decoders

let one_of decoders sexp =
  let rec go errors = function
    | (name, decoder) :: rest ->
      (match decoder sexp with
      | Ok result ->
        Ok result
      | Error error ->
        go
          (tag_errors ~msg:(Printf.sprintf "%S decoder" name) [ error ]
           :: errors)
          rest)
    | [] ->
      Error
        (tag_errors
           ~msg:"I tried the following decoders but they all failed"
           errors)
  in
  go [] decoders

(* Monadic operations *)

let return v _ = Ok v

let map ~f decoder sexp = Result.map (decoder sexp) ~f

let bind ~f decoder sexp =
  Result.bind (decoder sexp) ~f:(fun result -> f result sexp)

let apply f decoder sexp =
  match f sexp, decoder sexp with
  | Error e1, Error e2 ->
    Error (merge_errors e1 e2)
  | Error e, _ ->
    Error e
  | _, Error e ->
    Error e
  | Ok g, Ok x ->
    Ok (g x)

let product d1 d2 sexp =
  match d1 sexp, d2 sexp with
  | Error e1, Error e2 ->
    Error (merge_errors e1 e2)
  | Error e, _ ->
    Error e
  | _, Error e ->
    Error e
  | Ok a, Ok b ->
    Ok (a, b)

module Infix = struct
  let ( >|= ) decoder f = map decoder ~f

  let ( >>= ) decoder f = bind decoder ~f

  let ( <*> ) f decoder = apply f decoder
end

include Infix

module Let_syntax = struct
  let ( let* ) decoder f = bind decoder ~f

  let ( let+ ) decoder f = map decoder ~f

  let ( and+ ) d1 d2 = product d1 d2
end

include Let_syntax

let decode_sexp ~f sexp = f sexp

let decode_string ~f s =
  let open Result.Let_syntax in
  let* sexp = of_string s in
  decode_sexp ~f sexp

let decode_sexps_string ~f s =
  let open Result.Let_syntax in
  let* sexp = of_sexps_string s in
  decode_sexp ~f sexp

let decode_file ~f file =
  let open Result.Let_syntax in
  let* sexp = of_file file in
  decode_sexp sexp ~f

let decode_sexps_file ~f file =
  let open Result.Let_syntax in
  let* sexp = of_sexps_file file in
  decode_sexp sexp ~f
