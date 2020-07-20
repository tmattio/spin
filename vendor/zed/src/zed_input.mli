(*
 * zed_input.mli
 * -------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Zed, an editor engine.
 *)

(** Helpers for writing key bindings *)

(** Signature for binders. *)
module type S = sig

  type event
    (** Type of events. *)

  type +'a t
    (** Type of set of bindings mapping input sequence to values of
        type ['a]. *)

  val empty : 'a t
    (** The empty set of bindings. *)

  val add : event list -> 'a -> 'a t -> 'a t
    (** [add events x bindings] binds [events] to [x]. It raises
        [Invalid_argument] if [events] is empty. *)

  val remove : event list -> 'a t -> 'a t
    (** [remove events bindings] unbinds [events]. It raises
        [Invalid_argument] if [events] is empty. *)

  val fold : (event list -> 'a -> 'b -> 'b) -> 'a t -> 'b -> 'b
    (** [fold f set acc] executes [f] on all sequence of [set],
        accumulating a value. *)

  val bindings : 'a t -> (event list * 'a) list
    (** [bindings set] returns all bindings of [set]. *)

  type 'a resolver
    (** Type of a resolver. A resolver is used to resolve an input
        sequence, i.e. to find the value associated to one. It returns
        a value of type ['a] when a matching sequence is found. *)

  type 'a pack
    (** A pack is a pair of a set of bindings and a mapping
        function. *)

  val pack : ('a -> 'b) -> 'a t -> 'b pack
    (** [pack f set] creates a pack. *)

  val resolver : 'a pack list -> 'a resolver
    (** [resolver packs] creates a resolver from a list of pack. *)

  (** Result of a resolving operation. *)
  type 'a result =
    | Accepted of 'a
        (** The sequence is terminated and associated to the given
            value. *)
    | Continue of 'a resolver
        (** The sequence is not terminated. *)
    | Rejected
        (** None of the sequences is prefixed by the one. *)

  val resolve : event -> 'a resolver -> 'a result
    (** [resolve event resolver] tries to resolve [event] using
        [resolver]. *)
end

module Make (Event : Map.OrderedType) : S with type event = Event.t
  (** [Make (Event)] makes a a new binder. *)
