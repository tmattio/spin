open Lwt.Syntax

type pool = (Caqti_lwt.connection, Caqti_error.t) Caqti_lwt.Pool.t

type ('res, 'err) query =
  Caqti_lwt.connection -> ('res, ([< Caqti_error.t ] as 'err)) Lwt_result.t

type 'a result = ('a, Caqti_error.t) Lwt_result.t

type connection = (module Caqti_lwt.CONNECTION)

let log_src = Logs.Src.create ~doc:"Database requests." "demo.db"

module Log = (val Logs_lwt.src_log log_src : Logs_lwt.LOG)

let connect () =
  Config.database_uri |> Uri.of_string |> Caqti_lwt.connect_pool ~max_size:10
  |> function
  | Ok pool ->
    pool
  | Error err ->
    failwith (Caqti_error.show err)

let default_pool = connect ()

let map_error result =
  let open Lwt.Syntax in
  let* result = result in
  match result with
  | Ok v ->
    Lwt.return (Ok v)
  | Error err ->
    Error (`Internal_error err) |> Lwt.return

let map_error_opt result =
  let open Lwt.Syntax in
  let* result = result in
  match result with
  | Ok v ->
    Option.to_result v ~none:`Not_found |> Lwt.return
  | Error err ->
    Error (`Internal_error err) |> Lwt.return

let query ?(pool = default_pool) query =
  let* () = Log.info (fun m -> m "DB: Sending request to database") in
  let* result =
    Caqti_lwt.Pool.use query pool
    |> Lwt_result.map_err Caqti_error.show
    |> map_error
  in
  match result with
  | Ok _ ->
    Lwt.return result
  | Error (`Internal_error err) ->
    let* () =
      Log.err (fun m ->
          m "DB: an error occured while processing the request: %s" err)
    in
    Lwt.return result
  | Error _ ->
    Lwt.return result

let query_opt ?(pool = default_pool) query =
  let* () =
    Log.info (fun m -> m "DB: Sending request to database with optional result")
  in
  let* result =
    Caqti_lwt.Pool.use query pool
    |> Lwt_result.map_err Caqti_error.show
    |> map_error_opt
  in
  match result with
  | Ok _ ->
    Lwt.return result
  | Error (`Internal_error err) ->
    let* () =
      Log.err (fun m ->
          m "DB: an error occured while processing the request: %s" err)
    in
    Lwt.return result
  | _ ->
    Lwt.return result

type mode =
  | ReadUncommitted
  | ReadCommitted
  | RepeatableRead
  | Serializable

let string_of_mode = function
  | ReadUncommitted ->
    "READ UNCOMMITTED"
  | ReadCommitted ->
    "READ COMMITTED"
  | RepeatableRead ->
    "REPEATABLE READ"
  | Serializable ->
    "SERIALIZABLE"

let with_transaction ?(mode = ReadCommitted) (module C : Caqti_lwt.CONNECTION) f
  =
  let open Lwt_result.Syntax in
  let set_transaction_mode_query mode =
    Caqti_request.exec
      ~oneshot:true
      Caqti_type.unit
      (Printf.sprintf
         "set transaction isolation level %s;"
         (string_of_mode mode))
  in
  let* () = C.start () in
  let* () = C.exec (set_transaction_mode_query mode) () in
  Lwt.bind
    (f (module C : Caqti_lwt.CONNECTION))
    (function
      | Ok a ->
        let* () = C.commit () in
        Lwt.return_ok a
      | Error e ->
        let* () = C.rollback () in
        Lwt.return_error e)

let transaction ?(mode = ReadCommitted) ?(pool = default_pool) f =
  let f (module C : Caqti_lwt.CONNECTION) =
    with_transaction ~mode (module C : Caqti_lwt.CONNECTION) f
  in
  query ~pool f

let transaction_opt ?(mode = ReadCommitted) ?(pool = default_pool) f =
  let f (module C : Caqti_lwt.CONNECTION) =
    with_transaction ~mode (module C : Caqti_lwt.CONNECTION) f
  in
  query_opt ~pool f
