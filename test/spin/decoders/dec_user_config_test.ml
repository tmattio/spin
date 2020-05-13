open Alcotest
open Spin
open Test_utils

let test_encode_config () =
  let t =
    Dec_user_config.
      { username = Some "Bill"
      ; email = Some "bill@email.com"
      ; github_username = Some "bill"
      ; npm_username = Some "bill"
      }
  in
  let f = Dec_user_config.encode in
  let encoded = Encoder.encode_sexps_string t ~f in
  let expected =
    "(username Bill)\n\n\
     (email bill@email.com)\n\n\
     (github_username bill)\n\n\
     (npm_username bill)"
  in
  check string "same value" expected encoded

let suite = [ "can encode a config", `Quick, test_encode_config ]
