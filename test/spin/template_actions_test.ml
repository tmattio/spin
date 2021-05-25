open Alcotest
open Spin
open Spin_std

let spin_error = Alcotest.of_pp Spin_error.pp

let test_run_action () =
  let temp_file = "sample.ml" in
  let result_ =
    Template_actions.run
      Template_actions.
        { message = None
        ; actions =
            [ Template_actions.Run
                Template_actions.{ name = "touch"; args = [ temp_file ] }
            ]
        }
      ~path:(Filename.dirname temp_file)
  in
  check (result unit spin_error) "" (Ok ()) result_;
  check bool "file exists" true (Sys.file_exists temp_file)

let suite = [ "can run an action", `Quick, test_run_action ]
