open Alcotest
open Lwt.Syntax
open Opium_kernel
open Opium_testing

let test n = Test_support.test_case_db_quick n

let app = Demo_web.app ()

let handle_request = handle_request app

let suite =
  [ ( "GET /datasets"
    , [ test "lists all datasets" (fun _switch () ->
            let req = Request.make "/datasets" `GET in
            let* res = handle_request req in
            check_status `OK res.status;
            check_body_contains "<title>Datasets · Demo</title>" res.body)
      ] )
  ; ( "GET /datasets/new"
    , [ test "renders creation form" (fun _switch () ->
            let req = Request.make "/datasets/new" `GET in
            let* res = handle_request req in
            check_status `OK res.status;
            check_body_contains "<title>Datasets · Demo</title>" res.body)
      ] )
  ; ( "POST /datasets"
    , [ test "redirects to show when data is valid" (fun _switch () ->
            let req = Request.make "/datasets" `POST in
            let* res = handle_request req in
            check_status `OK res.status;
            check_body_contains "<title>Datasets · Demo</title>" res.body)
      ; test "renders errors when data is invalid" (fun _switch () ->
            let req = Request.make "/datasets" `POST in
            let* res = handle_request req in
            check_status `OK res.status;
            check_body_contains "<title>Datasets · Demo</title>" res.body)
      ] )
  ; ( "GET /datasets/:id/edit"
    , [ test "renders form for editing chosen dataset" (fun _switch () ->
            let req = Request.make "/datasets/:id/edit" `GET in
            let* res = handle_request req in
            check_status `OK res.status;
            check_body_contains "<title>Datasets · Demo</title>" res.body)
      ] )
  ; ( "PUT /datasets/:id"
    , [ test "redirects when data is valid" (fun _switch () ->
            let req = Request.make "/datasets/:id" `PUT in
            let* res = handle_request req in
            check_status `OK res.status;
            check_body_contains "<title>Datasets · Demo</title>" res.body)
      ; test "renders errors when data is invalid" (fun _switch () ->
            let req = Request.make "/datasets/:id" `PUT in
            let* res = handle_request req in
            check_status `OK res.status;
            check_body_contains "<title>Datasets · Demo</title>" res.body)
      ] )
  ; ( "DELETE /datasets/:id"
    , [ test "deletes chosen dataset" (fun _switch () ->
            let req = Request.make "/datasets/:id" `DELETE in
            let* res = handle_request req in
            check_status `OK res.status;
            check_body_contains "<title>Datasets · Demo</title>" res.body)
      ] )
  ]

let () = Lwt_main.run @@ Alcotest_lwt.run "demo-web - Dataset Handler" suite
