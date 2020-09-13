open Opium_kernel
open Lwt.Syntax
open Demo

let index_user req =
  let* users = Account.list_users () in
  match users with
  | Ok users ->
    Lwt.return @@ Response.of_html (Account_view.index_user ~users ())
  | Error (`Internal_error _) ->
    Lwt.return @@ Response.make ~status:`Internal_server_error ()

let new_user req = Lwt.return @@ Response.of_html (Account_view.new_user ())

let create_user req =
  let* result =
    let open Lwt_result.Syntax in
    let* name =
      Request.urlencoded "name" req
      |> Lwt.map
           (Option.to_result ~none:(`Msg "The name parameter is required."))
    in
    let* name = Account.User.Name.of_string name |> Lwt_result.lift in
    Account.create_user ~name ()
  in
  match result with
  | Ok user ->
    Lwt.return
    @@ Response.redirect_to ~status:`Found ("/users/" ^ string_of_int user.id)
  | Error err ->
    let message =
      match err with
      | `Msg reason ->
        reason
      | `Validation_error err ->
        err
      | `Already_exists ->
        "A user with the same name already exist"
      | `Internal_error _ ->
        "An internal error occured."
    in
    Lwt.return
    @@ Response.of_html (Account_view.new_user ~alert:(`error message) ())

let show_user req =
  let user_id = Opium_kernel.Router.param req "id" in
  let* user =
    try Account.get_user_by_id (int_of_string user_id) with
    | Failure _ ->
      Lwt.return (Error `Not_found)
  in
  match user with
  | Ok user ->
    Lwt.return @@ Response.of_html (Account_view.show_user ~user ())
  | Error (`Internal_error _) ->
    Lwt.return @@ Response.make ~status:`Internal_server_error ()
  | Error `Not_found ->
    Lwt.return @@ Response.make ~status:`Not_found ()

let edit_user req =
  let user_id = Opium_kernel.Router.param req "id" in
  let* user =
    try Account.get_user_by_id (int_of_string user_id) with
    | Failure _ ->
      Lwt.return (Error `Not_found)
  in
  match user with
  | Ok user ->
    Lwt.return @@ Response.of_html (Account_view.edit_user ~user ())
  | Error (`Internal_error _) ->
    Lwt.return @@ Response.make ~status:`Internal_server_error ()
  | Error `Not_found ->
    Lwt.return @@ Response.make ~status:`Not_found ()

let update_user _req = Lwt.return @@ Response.make ()

let delete_user _req = Lwt.return @@ Response.make ()
