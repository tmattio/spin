open Opium_kernel
open Demo
open Lwt.Syntax

let index_user req =
  let* users = Account.list_users () in
  match users with
  | Ok users ->
    let user = Hmap0.get User_auth_middleware.Env.key req.Rock.Request.env in
    Lwt.return @@ Helper.response_of_html (Account_view.index ~user ~users ())
  | Error (`Internal_error _) ->
    Lwt.return @@ Rock.Response.make ~status:`Internal_server_error ()

let new_user req =
  let user = Hmap0.get User_auth_middleware.Env.key req.Rock.Request.env in
  Lwt.return @@ Helper.response_of_html (Account_view.new_ ~user ())

let create_user req =
  let user = Hmap0.get User_auth_middleware.Env.key req.Rock.Request.env in
  let* result =
    let open Lwt_result.Syntax in
    let* name =
      Lwt.map
        (Result.map_error (fun err -> `Query_error err))
        (Common.Request.urlencoded req "name")
    in
    let* name = Account.User.Name.of_string name |> Lwt_result.lift in
    Account.create_user ~name ~user ()
  in
  match result with
  | Ok user ->
    Lwt.return
    @@ Common.Response.redirect_to
         ~status:`Found
         ("/users/" ^ string_of_int user.id)
  | Error err ->
    let message =
      match err with
      | `Query_error reason ->
        reason
      | `Validation_error err ->
        err
      | `Internal_error _ ->
        "An internal error occured."
    in
    Lwt.return
    @@ Helper.response_of_html
         (Account_view.new_ ~user ~alert:(`error message) ())

let show_user req =
  let user_id = Opium_kernel.Router.param req "id" in
  let* user =
    try Account.get_user_by_id (int_of_string user_id) with
    | Failure _ ->
      Lwt.return (Error `Not_found)
  in
  match user with
  | Ok user ->
    Lwt.return @@ Helper.response_of_html (Account_view.show ~user ~user ())
  | Error (`Internal_error _) ->
    Lwt.return @@ Rock.Response.make ~status:`Internal_server_error ()
  | Error `Not_found ->
    Lwt.return @@ Rock.Response.make ~status:`Not_found ()

let edit_user req =
  let user_id = Opium_kernel.Router.param req "id" in
  let* user =
    try Account.get_user_by_id (int_of_string user_id) with
    | Failure _ ->
      Lwt.return (Error `Not_found)
  in
  match user with
  | Ok user ->
    Lwt.return @@ Helper.response_of_html (Account_view.edit ~user ~user ())
  | Error (`Internal_error _) ->
    Lwt.return @@ Rock.Response.make ~status:`Internal_server_error ()
  | Error `Not_found ->
    Lwt.return @@ Rock.Response.make ~status:`Not_found ()

let update_user _req = Lwt.return @@ Rock.Response.of_string "" ~status:`OK

let delete_user _req = Lwt.return @@ Rock.Response.of_string "" ~status:`OK
