open Alcotest
open Lwt.Syntax
open Opium_kernel

let test_case n = Test_support.test_case_db n `Quick

let suite =
  [ ( "GET /"
    , [ test_case "renders the index page" (fun _switch () ->
            let req = Rock.Request.make "/" `GET () in
            let* res = Test_support.handle_request req in
            Test_support.check_status `OK res.status;
            Test_support.check_body_contains
              "<title>{{ project_description }} · Demo</title>"
              res.body)
      ] )
  ; ( "GET /page_not_found"
    , [ test_case "renders the not found error page" (fun _switch () ->
            let req = Rock.Request.make "/page_not_found" `GET () in
            let* res = Test_support.handle_request req in
            Test_support.check_status `Not_found res.status;
            Test_support.check_body_contains
              "<title>Page not found · Demo</title>"
              res.body)
      ] )
  ]

let () = Lwt_main.run @@ Alcotest_lwt.run "demo-web - Page Handler" suite
