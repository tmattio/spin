(* This module is heavily inspired by
   https://github.com/mattjbray/ocaml-decoders/ *)

open Sexplib0

type error =
  | Decoder_error of string * Sexp.t option
  | Decoder_errors of error list
  | Decoder_tag of string * error

type 'a t = Sexp.t -> ('a, error) Result.t

(** {2 Error handling} *)

val pp_error : Format.formatter -> error -> unit
(** Pretty-print an [error]. *)

val string_of_error : error -> string
(** Convert an [error] to a [string]. *)

(** {2 Loading s-expressions} *)

val of_string : string -> (Sexp.t, error) Result.t
(** Load an s-expression from a string. *)

val of_sexps_string : string -> (Sexp.t, error) Result.t
(** Load a list of s-expression from a string. *)

val of_file : string -> (Sexp.t, error) Result.t
(** Load an s-expression from a file. *)

val of_sexps_file : string -> (Sexp.t, error) Result.t
(** Load a list of s-expression from a file. *)

(** {2 Decoding primitives} *)

val string : string t
(** Decode a [string]. *)

val int : int t
(** Decode an [int]. *)

val float : float t
(** Decode a [float]. *)

val bool : bool t
(** Decode a [bool]. *)

val null : unit t
(** Decode a [null]. *)

(** {2 Helpers} *)

val string_matching : regex:string -> err:string -> string t

(** {2 Decoding lists} *)

val list : 'a t -> 'a list t
(** Decode a collection into an OCaml list. *)

(** {2 Decoding records} *)

val field : string -> 'a t -> 'a t
(** Decode a record from the field with the given name.

    This will fail with an error if the field could not be found. It will also
    fail if several fields exist with the same name. Use [fields] if you want to
    decode a list of fields. *)

val fields : string -> 'a t -> 'a list t
(** Decode a list of record from the fields with the given name.

    It returns an empty list if no fields with the given name exist. *)

val field_opt : string -> 'a t -> 'a option t
(** Decode a record from the field with the given name.

    This will return [None] if the field could not be found. It will fail if
    several fields exist with the same name. Use [fields] if you want to decode
    a list of fields. *)

(** {2 Inconsistent structure} *)

val one_of_opt : (string * 'a t) list -> 'a option t
(** Try a sequence of different decoders. *)

val one_of : (string * 'a t) list -> 'a t
(** Try a sequence of different decoders and return an error if none of them
    worked. *)

(** {2 Monadic operations} *)

val return : 'a -> 'a t
(** Lift decoder from a value. *)

val map : ('a -> 'b) -> 'a t -> 'b t
(** Map over the output of a decoder. *)

val bind : 'a t -> ('a -> 'b t) -> 'b t
(** Create decoders that depend on previous outputs. *)

val product : 'a t -> 'b t -> ('a * 'b) t
(** Try two decoders and then combine the Result.t. We can use this to decode
    objects with many fields *)

module Infix : sig
  val ( >|= ) : 'a t -> ('a -> 'b) -> 'b t

  val ( >>= ) : 'a t -> ('a -> 'b t) -> 'b t

  val ( <*> ) : ('a -> 'b) t -> 'a t -> 'b t
end

include module type of Infix

module Syntax : sig
  val ( let* ) : 'a t -> ('a -> 'b t) -> 'b t

  val ( let+ ) : 'a t -> ('a -> 'b) -> 'b t

  val ( and+ ) : 'a t -> 'b t -> ('a * 'b) t
end

include module type of Syntax

(** {2 Running decoders} *)

val decode_sexp : Sexp.t -> 'a t -> ('a, error) Result.t
(** Run a decoder on some input. *)

val decode_string : string -> 'a t -> ('a, error) Result.t
(** Run a decoder on a string. *)

val decode_sexps_string : string -> 'a t -> ('a, error) Result.t
(** Run a decoder on a string containing a list of s-expression. *)

val decode_file : string -> 'a t -> ('a, error) Result.t
(** Run a decoder on a file. *)

val decode_sexps_file : string -> 'a t -> ('a, error) Result.t
(** Run a decoder on a file containing a list of s-expression. *)
