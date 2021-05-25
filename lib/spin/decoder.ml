(* This module is heavily inspired by
   https://github.com/mattjbray/ocaml-decoders/ *)

open Sexplib0

type error =
  | Decoder_error of string * Sexp.t option
  | Decoder_errors of error list
  | Decoder_tag of string * error

type 'a t = Sexp.t -> ('a, error) Result.t

(* Error handling *)

let pp_sexp fmt value = Format.fprintf fmt "@[%a@]" Sexp.pp_hum value

let rec pp_error fmt = function
  | Decoder_error (msg, Some t) ->
    Format.fprintf fmt "@[%s, but got@ @[%a@]@]" msg pp_sexp t
  | Decoder_error (msg, None) ->
    Format.fprintf fmt "@[%s@]" msg
  | Decoder_errors errors ->
    Format.fprintf
      fmt
      "@[%a@]"
      (Format.pp_print_list ~pp_sep:Format.pp_print_space pp_error)
      errors
  | Decoder_tag (msg, error) ->
    Format.fprintf fmt "@[<2>%s:@ @[%a@]@]" msg pp_error error

let string_of_error error = Format.asprintf "@[<2>%a@?@]" pp_error error

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
  Result.map_error
    (fun msg ->
      Decoder_tag ("S-Expression parsing error", Decoder_error (msg, None)))
    result

let of_sexps_string (s : string) =
  let s = "(" ^ s ^ ")" in
  of_string s

let of_file s =
  let content = Sys.read_file s in
  of_string content

let of_sexps_file s =
  let content = Sys.read_file s in
  of_sexps_string content

(* Decoding primitives *)

let decode_primitive f ~err = function
  | Sexp.Atom _ as sexp ->
    (try Ok (f sexp) with
    | Sexp_conv.Of_sexp_error _ ->
      Error (decoder_error ~msg:err sexp))
  | sexp ->
    Error (decoder_error ~msg:"Expected a single value" sexp)

let string = decode_primitive Sexp_conv.string_of_sexp ~err:"Expected a string"

let int = decode_primitive Sexp_conv.int_of_sexp ~err:"Expected an int"

let float = decode_primitive Sexp_conv.float_of_sexp ~err:"Expected a float"

let bool = decode_primitive Sexp_conv.bool_of_sexp ~err:"Expected a bool"

let null = decode_primitive Sexp_conv.unit_of_sexp ~err:"Expected a unit"

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
    List.mapi
      (fun i x ->
        decoder x
        |> Result.map_error (fun error ->
               tag_error ~msg:(Printf.sprintf "element %i" i) error))
      sexps
    |> combine_errors
    |> Result.map_error (fun errors ->
           tag_errors ~msg:"while decoding a list" errors)

(* Decoding records *)

let key_value_pairs = function
  | Sexp.List l ->
    let kv_pairs_opt =
      List.map
        (function
          | Sexp.List [ key; value ] ->
            Some (key, value)
          | Sexp.List (key :: values) ->
            Some (key, Sexp.List values)
          | _ ->
            None)
        l
    in
    let all_some l =
      try Some (List.map (function Some x -> x | None -> raise Exit) l) with
      | Exit ->
        None
    in
    all_some kv_pairs_opt
  | _ ->
    None

let field_opt key f sexp =
  let value =
    match sexp with
    | Sexp.List [ Sexp.Atom s; value ] when String.equal s key ->
      Some value
    | Sexp.List (Sexp.Atom s :: values) when String.equal s key ->
      Some (Sexp.List values)
    | _ ->
      (match key_value_pairs sexp with
      | Some kv_pairs ->
        List.find_map
          (fun (k, v) ->
            match string k with
            | Ok s when String.equal s key ->
              Some v
            | _ ->
              None)
          kv_pairs
      | _ ->
        None)
  in
  match value with
  | Some value ->
    f value
    |> Result.map Option.some
    |> Result.map_error (fun error ->
           tag_error ~msg:(Printf.sprintf "Error in field %S" key) error)
  | None ->
    Ok None

let field key f sexp =
  match field_opt key f sexp with
  | Ok None ->
    Error
      (decoder_error
         ~msg:(Printf.sprintf "Expected an s-expression with a field %S" key)
         sexp)
  | Ok (Some v) ->
    Ok v
  | Error e ->
    Error e

let fields key f sexp =
  let values =
    match sexp with
    | Sexp.List [ Sexp.Atom s; value ] when String.equal s key ->
      [ value ]
    | Sexp.List (Sexp.Atom s :: values) when String.equal s key ->
      [ Sexp.List values ]
    | _ ->
      (match key_value_pairs sexp with
      | Some kv_pairs ->
        List.fold_left
          (fun acc (k, v) ->
            match string k with
            | Ok s when String.equal s key ->
              v :: acc
            | _ ->
              acc)
          []
          kv_pairs
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

let map f decoder sexp = Result.map f (decoder sexp)

let bind decoder f sexp =
  Result.bind (decoder sexp) (fun result -> f result sexp)

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
  let ( >|= ) decoder f = map f decoder

  let ( >>= ) decoder f = bind decoder f

  let ( <*> ) f decoder = apply f decoder
end

include Infix

module Syntax = struct
  let ( let* ) decoder f = bind decoder f

  let ( let+ ) decoder f = map f decoder

  let ( and+ ) d1 d2 = product d1 d2
end

include Syntax

let decode_sexp sexp f = f sexp

let decode_string s f =
  let open Result.Syntax in
  let* sexp = of_string s in
  decode_sexp sexp f

let decode_sexps_string s f =
  let open Result.Syntax in
  let* sexp = of_sexps_string s in
  decode_sexp sexp f

let decode_file file f =
  let open Result.Syntax in
  let* sexp = of_file file in
  decode_sexp sexp f

let decode_sexps_file file f =
  let open Result.Syntax in
  let* sexp = of_sexps_file file in
  decode_sexp sexp f
