module Name : sig
  type t [@@deriving show, eq]

  val of_string : string -> (t, [> `Validation_error of string ]) result

  val to_string : t -> string

  val t : t Caqti_type.t
end

type t =
  { id : int
  ; name : Name.t
  ; created_at : Ptime.t
  ; updated_at : Ptime.t
  }
[@@deriving show, eq]

val get_all : unit -> (t list, [> `Internal_error of string ]) Lwt_result.t
(** Get all the users. *)

val get_by_id
  :  int
  -> (t, [> `Internal_error of string | `Not_found ]) Lwt_result.t
(** Get a user by id. *)

val create
  :  name:Name.t
  -> unit
  -> (t, [> `Internal_error of string ]) Lwt_result.t
(** Create a new user with the name [name]. *)

val update
  :  ?name:Name.t
  -> t
  -> (t, [> `Internal_error of string ]) Lwt_result.t
(** Update the user with [name]. *)

val delete : t -> (unit, [> `Internal_error of string ]) Lwt_result.t
(** Delete the user. *)
