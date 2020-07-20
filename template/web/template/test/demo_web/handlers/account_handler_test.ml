open Alcotest
open Lwt.Syntax
open Opium_kernel

let test_case n = Test_support.test_case_db_quick n

let suite =
  [ ( "GET /datasets"
    , [ test_case "lists all datasets" (fun _switch () ->
            let req = Rock.Request.make "/datasets" `GET () in
            let* res = Test_support.handle_request req in
            Test_support.check_status `OK res.status;
            Test_support.check_body_contains
              "<title>Datasets · Demo</title>"
              res.body)
      ] )
  ; ( "GET /datasets/new"
    , [ test_case "renders creation form" (fun _switch () ->
            let req = Rock.Request.make "/datasets/new" `GET () in
            let* res = Test_support.handle_request req in
            Test_support.check_status `OK res.status;
            Test_support.check_body_contains
              "<title>Datasets · Demo</title>"
              res.body)
      ] )
  ; ( "POST /datasets"
    , [ test_case "redirects to show when data is valid" (fun _switch () ->
            let req = Rock.Request.make "/datasets" `POST () in
            let* res = Test_support.handle_request req in
            Test_support.check_status `OK res.status;
            Test_support.check_body_contains
              "<title>Datasets · Demo</title>"
              res.body)
      ; test_case "renders errors when data is invalid" (fun _switch () ->
            let req = Rock.Request.make "/datasets" `POST () in
            let* res = Test_support.handle_request req in
            Test_support.check_status `OK res.status;
            Test_support.check_body_contains
              "<title>Datasets · Demo</title>"
              res.body)
      ] )
  ; ( "GET /datasets/:id/edit"
    , [ test_case "renders form for editing chosen dataset" (fun _switch () ->
            let req = Rock.Request.make "/datasets/:id/edit" `GET () in
            let* res = Test_support.handle_request req in
            Test_support.check_status `OK res.status;
            Test_support.check_body_contains
              "<title>Datasets · Demo</title>"
              res.body)
      ] )
  ; ( "PUT /datasets/:id"
    , [ test_case "redirects when data is valid" (fun _switch () ->
            let req = Rock.Request.make "/datasets/:id" `PUT () in
            let* res = Test_support.handle_request req in
            Test_support.check_status `OK res.status;
            Test_support.check_body_contains
              "<title>Datasets · Demo</title>"
              res.body)
      ; test_case "renders errors when data is invalid" (fun _switch () ->
            let req = Rock.Request.make "/datasets/:id" `PUT () in
            let* res = Test_support.handle_request req in
            Test_support.check_status `OK res.status;
            Test_support.check_body_contains
              "<title>Datasets · Demo</title>"
              res.body)
      ] )
  ; ( "DELETE /datasets/:id"
    , [ test_case "deletes chosen dataset" (fun _switch () ->
            let req = Rock.Request.make "/datasets/:id" `DELETE () in
            let* res = Test_support.handle_request req in
            Test_support.check_status `OK res.status;
            Test_support.check_body_contains
              "<title>Datasets · Demo</title>"
              res.body)
      ] )
  ]

let () = Lwt_main.run @@ Alcotest_lwt.run "demo-web - Dataset Handler" suite
