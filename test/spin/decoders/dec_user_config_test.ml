open Alcotest
open Spin
open Test_utils

let test_encode_config () =
  let t =
    Dec_user_config.
      { author_name = Some "Bill"
      ; email = Some "bill@email.com"
      ; github_username = Some "bill"
      ; create_switch = Some false
      }
  in
  let f = Dec_user_config.encode in
  let encoded = Encoder.encode_sexps_string t f in
  let expected =
    "(author_name Bill)\n\n\
     (email bill@email.com)\n\n\
     (github_username bill)\n\n\
     (create_switch false)"
  in
  check string "same value" expected encoded

let suite = [ "can encode a config", `Quick, test_encode_config ]
