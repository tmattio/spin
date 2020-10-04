open Spin_test

(** Main entry point for our test runner.

    This aggregates all the test suites and call Alcotes to run them. When
    creating a new test suite, don't forget to add it here! *)
    
let () =
  Alcotest.run
    "spin"
    [
       (* "spin::Dec_common", Dec_common_test.suite *)
    (* ; "spin::Dec_user_config", Dec_user_config_test.suite *)
    (* ; "spin::Decoder", Decoder_test.suite *)
    (* Disable because it depends on Reason. Only uncomment in development. *)
     "spin::Template_actions", Template_actions_test.suite
    (* ; "spin_std::Spin_sys", Spin_sys_test.suite *)
    ]
