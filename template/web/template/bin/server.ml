let rock = Demo_web.app ()

let app =
  let app = Opium.App.empty in
  List.fold_right
    rock.Opium_kernel.Rock.App.middlewares
    ~init:app
    ~f:(fun m app -> Opium.App.middleware m app)
  |> Opium.App.not_found (fun req ->
         let open Lwt.Syntax in
         let+ resp = rock.Opium_kernel.Rock.App.handler req in
         let headers = resp.headers in
         let body = resp.body in
         headers, body)
  |> Opium.App.cmd_name "Demo"

let setup_logger ?(log_level = Logs.Info) () =
  Fmt_tty.setup_std_outputs ();
  Logs.set_level (Some log_level);
  Logs.set_reporter (Logs_fmt.reporter ~app:Fmt.stdout ())

let () =
  setup_logger ~log_level:Logs.Debug ();
  Opium.App.run_command app
