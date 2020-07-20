(** The User context. *)

module Error : sig
  type t = [ | Error.t ] [@@deriving show, eq]
end

module User = Account_user

val list_users
  :  unit
  -> (User.t list, [> `Internal_error of string ]) Lwt_result.t
(** Returns the list of the users.

    {4 Examples}

    {[
      list_users ()
      _ : (User.t list, Error.t) Lwt_result.t = Ok _
    ]} *)

val get_user_by_id
  :  int
  -> (User.t, [> `Internal_error of string | `Not_found ]) Lwt_result.t
(** Gets a single user.

    {4 Examples}

    {[
      get_user_by_id 123
      _ : (User.t, Error.t) Lwt_result.t = Ok { id = 123 ; _ }

      get_user_by_id 456
      _ : (User.t, Error.t) Lwt_result.t = Error _
    ]} *)

val create_user
  :  name:User.Name.t
  -> unit
  -> (User.t, [> `Already_exists | `Internal_error of string ]) Lwt_result.t
(** Gets a single user.

    {4 Examples}

    {[
      create_user ~name:"valid"
      _ : (User.t, Error.t) Lwt_result.t = Ok { id = 123 ; _ }

      create_user ~name:"invalid"
      _ : (User.t, Error.t) Lwt_result.t = Error _
    ]} *)

val update_user
  :  ?name:User.Name.t
  -> User.t
  -> (User.t, [> `Internal_error of string ]) Lwt_result.t
(** Updates a user.

    {4 Examples}

    {[
      update_user ~name:"valid" user
      _ : (User.t, Error.t) Lwt_result.t = Ok { id = 123 ; _ }

      update_user ~name:"invalid" user
      _ : (User.t, Error.t) Lwt_result.t = Error _
    ]} *)

val delete_user : User.t -> (unit, [> `Internal_error of string ]) Lwt_result.t
(** Deletes a user.

    {4 Examples}

    {[
      delete_user user
      _ : (unit, Error.t) Lwt_result.t = Ok { id = 123 ; _ }

      delete_user user
      _ : (unit, Error.t) Lwt_result.t = Error _
    ]} *)
