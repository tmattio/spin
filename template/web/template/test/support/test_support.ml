let setup_logger ?(log_level = Logs.Info) () =
  Fmt_tty.setup_std_outputs ();
  Logs.set_level (Some log_level);
  Logs.set_reporter (Logs_fmt.reporter ~app:Fmt.stdout ())

let tables_to_clean = [ "users" ]

let clean_all () =
  let open Lwt.Syntax in
  let rec run_clean = function
    | [] ->
      Lwt_result.return ()
    | table :: tables ->
      let open Lwt_result.Syntax in
      let query connection =
        let module Connection = (val connection : Caqti_lwt.CONNECTION) in
        let request =
          Caqti_request.exec
            Caqti_type.unit
            (Format.asprintf "TRUNCATE TABLE %s CASCADE;" table)
        in
        Connection.exec request ()
      in
      let* _ = Demo.Repo.query query in
      run_clean tables
  in
  Lwt_result.bind_lwt_err (run_clean tables_to_clean) (function
      | `Internal_error error ->
      let* () =
        Logs_lwt.err (fun m -> m "DB: Failed to clean a table: %s" error)
      in
      Lwt.return error)

let test_case_db n s f =
  let open Lwt.Syntax in
  Alcotest_lwt.test_case n s (fun switch () ->
      let* result = clean_all () in
      (* Fail if database clean failed *)
      let _ok = Result.get_ok result in
      f switch ())

let test_case_db_quick n = test_case_db n `Quick

let get_lwt_ok ~msg =
  Lwt.map (fun r -> try Result.get_ok r with _ -> Alcotest.fail msg)

let get_ok ~msg r = try Result.get_ok r with _ -> Alcotest.fail msg
