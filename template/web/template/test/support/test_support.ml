let setup_logger ?(log_level = Logs.Info) () =
  Fmt_tty.setup_std_outputs ();
  Logs.set_level (Some log_level);
  Logs.set_reporter (Logs_fmt.reporter ~app:Fmt.stdout ())

module Testable = struct
  let status = Alcotest.of_pp Opium_kernel.Rock.Status.pp_hum

  let method_ = Alcotest.of_pp Opium_kernel.Rock.Method.pp_hum

  let version = Alcotest.of_pp Opium_kernel.Rock.Version.pp_hum

  let body = Alcotest.of_pp Opium_kernel.Rock.Body.pp_hum

  let request = Alcotest.of_pp Opium_kernel.Rock.Request.pp_hum

  let response = Alcotest.of_pp Opium_kernel.Rock.Response.pp_hum
end

let test_case_db n s f =
  let open Lwt.Syntax in
  Alcotest_lwt.test_case n s (fun switch () ->
      let* result = Demo.Repo.clean_all () in
      (* Fail if database clean failed *)
      let _ok = Result.get_ok result in
      f switch ())

let test_case_db_quick n = test_case_db n `Quick

let handle_request =
  let open Opium_kernel in
  let open Lwt.Syntax in
  let app = Demo_web.app () in
  let { Rock.App.middlewares; handler } = app in
  let filters =
    ListLabels.map ~f:(fun m -> m.Rock.Middleware.filter) middlewares
  in
  let service = Rock.Filter.apply_all filters handler in
  let request_handler request =
    let+ ({ Rock.Response.body; headers; _ } as response) = service request in
    let { Rock.Body.length; _ } = body in
    let headers =
      match length with
      | None ->
        Rock.Headers.add_unless_exists headers "transfer-encoding" "chunked"
      | Some l ->
        Rock.Headers.add_unless_exists
          headers
          "content-length"
          (Int64.to_string l)
    in
    { response with headers }
  in
  request_handler

let get_lwt_ok ~msg =
  Lwt.map (fun r -> try Result.get_ok r with _ -> Alcotest.fail msg)

let get_ok ~msg r = try Result.get_ok r with _ -> Alcotest.fail msg

let check_status expected t =
  let message =
    Format.asprintf
      "response status is %d"
      (Opium_kernel.Rock.Status.to_code expected)
  in
  Alcotest.check Testable.status message expected t

let check_body_contains s body =
  let open Lwt.Syntax in
  let+ body = body |> Opium_kernel.Rock.Body.to_string in
  Alcotest.check
    Alcotest.bool
    ("response body contains " ^ s)
    true
    (String.contains_s ~sub:s body)
