open Alcotest
open Spin
open Test_utils

let test_decode_valid_name () =
  let f =
    let open Decoder.Let_syntax in
    let+ name = Decoder.field "name" ~f:Dec_common.Template_name.decode in
    name
  in
  let decoded = Decoder.decode_string "((name valid))" ~f in
  check (decoder string) "same value" (Ok "valid") decoded;
  let decoded = Decoder.decode_string "((name valid-with-dash))" ~f in
  check (decoder string) "same value" (Ok "valid-with-dash") decoded;
  let decoded = Decoder.decode_string "((name valid_with_underscore))" ~f in
  check (decoder string) "same value" (Ok "valid_with_underscore") decoded

let test_decode_invalid_name () =
  let f =
    let open Decoder.Let_syntax in
    let+ name = Decoder.field "name" ~f:Dec_common.Template_name.decode in
    name
  in
  let decoded = Decoder.decode_string {|((name "with space"))|} ~f in
  match decoded with Error _ -> () | Ok _ -> fail "name should not be decoded"

let suite =
  [ "can decode a valid template name", `Quick, test_decode_valid_name
  ; "fails to decode an invalid template name", `Quick, test_decode_invalid_name
  ]
