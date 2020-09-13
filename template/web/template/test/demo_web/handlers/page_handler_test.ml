open Alcotest
open Lwt.Syntax
open Opium_kernel
open Opium_testing

let test n = Test_support.test_case_db n `Quick

let app = Demo_web.app ()

let handle_request = handle_request app

let suite =
  [ ( "GET /"
    , [ test "renders the index page" (fun _switch () ->
            let req = Request.make "/" `GET in
            let* res = handle_request req in
            check_status `OK res.status;
            check_body_contains
              "<title>{{ project_description }} · Demo</title>"
              res.body)
      ] )
  ; ( "GET /page_not_found"
    , [ test "renders the not found error page" (fun _switch () ->
            let req = Request.make "/page_not_found" `GET in
            let* res = handle_request req in
            check_status `Not_found res.status;
            check_body_contains "<title>Page not found · Demo</title>" res.body)
      ] )
  ]

let () = Lwt_main.run @@ Alcotest_lwt.run "demo-web - Page Handler" suite
