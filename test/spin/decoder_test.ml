open Alcotest
open Spin
open Test_utils

let test_decode_field_of_string () =
  let f =
    let open Decoder.Let_syntax in
    let+ v = Decoder.field "field" ~f:Decoder.string in
    v
  in
  let decoded = Decoder.decode_string "((field value))" ~f in
  check (decoder string) "same value" (Ok "value") decoded

let test_decode_field_of_list () =
  let f =
    let open Decoder.Let_syntax in
    let+ v = Decoder.field "field" ~f:(Decoder.list Decoder.int) in
    v
  in
  let decoded = Decoder.decode_string "((field 1 2 3))" ~f in
  check (decoder (list int)) "same value" (Ok [ 1; 2; 3 ]) decoded;
  let decoded = Decoder.decode_string "((field (1 2 3)))" ~f in
  check (decoder (list int)) "same value" (Ok [ 1; 2; 3 ]) decoded

let test_decode_field_opt () =
  let f =
    let open Decoder.Let_syntax in
    let+ v = Decoder.field_opt "field" ~f:Decoder.string in
    v
  in
  let decoded = Decoder.decode_string "((field value))" ~f in
  check (decoder (option string)) "same value" (Ok (Some "value")) decoded;
  let decoded = Decoder.decode_string "()" ~f in
  check (decoder (option string)) "same value" (Ok None) decoded

let suite =
  [ "can decode a field of string", `Quick, test_decode_field_of_string
  ; "can decode a field of list", `Quick, test_decode_field_of_list
  ; "can decode an optional field", `Quick, test_decode_field_opt
  ]
