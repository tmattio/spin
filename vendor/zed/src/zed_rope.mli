(*
 * zed_rope.mli
 * ------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Copyright : (c) 2019, ZAN DoYe <zandoye@gmail.com>
 * Licence   : BSD3
 *
 * This file is a part of Zed, an editor engine.
 *)

(** Unicode ropes *)

type t
  (** Type of unicode ropes. *)

type rope = t
    (** Alias. *)

exception Out_of_bounds
  (** Exception raised when trying to access a character which is
      outside the bounds of a rope. *)

(** {5 Construction} *)

val empty : unit -> rope
  (** The empty rope. *)

val make : int -> Zed_char.t -> rope
  (** [make length char] creates a rope of length [length] containing only [char]. *)

val singleton : Zed_char.t -> rope
  (** [singleton ch] creates a rope of length 1 containing only [ch]. *)

(** {5 Informations} *)

val length : rope -> int
  (** Returns the length of the given rope. *)

val size : rope -> int
  (** Returns the size of the given rope. *)

val is_empty : rope -> bool
  (** [is_empty rope] returns whether [str] is the empty rope or not. *)


(** {5 Random access} *)

val get : rope -> int -> Zed_char.t
  (** [get rope idx] returns the glyph at index [idx] in [rope]. *)

val get_raw : rope -> int -> Uchar.t
  (** [get_raw rope idx] returns the character at raw index [idx] in
      [rope]. *)

(** {5 Rope manipulation} *)

val append : rope -> rope -> rope
  (** Concatenates the two given ropes. *)

val concat : rope -> rope list -> rope
  (** [concat sep l] concatenates all strings of [l] separating them
      by [sep]. *)

val sub : rope -> int -> int -> rope
  (** [sub rope ofs len] Returns the sub-rope of [rope] starting at
      [ofs] and of length [len]. *)

val break : rope -> int -> rope * rope
  (** [break rope pos] returns the sub-ropes before and after [pos] in
      [rope]. It is more efficient than creating two sub-ropes with
      {!sub}. *)

val before : rope -> int -> rope
  (** [before rope pos] returns the sub-rope before [pos] in [rope]. *)

val after : rope -> int -> rope
  (** [after rope pos] returns the sub-string after [pos] in [rope]. *)

val insert : rope -> int -> rope -> rope
  (** [insert rope pos sub] inserts [sub] in [rope] at position
      [pos]. *)

val insert_uChar : rope -> int -> Uchar.t -> rope
  (** [insert rope pos char] inserts [char] in [rope] at position
      [pos]. If [char] is a combing mark, it's merged to the character
      at position [pos-1] *)

val remove : rope -> int -> int -> rope
  (** [remove rope pos len] removes the [len] characters at position
      [pos] in [rope] *)

val replace : rope -> int -> int -> rope -> rope
  (** [replace rope pos len repl] replaces the [len] characters at
      position [pos] in [rope] by [repl]. *)

val lchop : rope -> rope
  (** [lchop rope] returns [rope] without is first character. Returns
      {!empty} if [rope] is empty. *)

val rchop : rope -> rope
  (** [rchop rope] returns [rope] without is last character. Returns
      {!empty} if [rope] is empty. *)

(** {5 Iteration, folding and mapping} *)

val iter : (Zed_char.t -> unit) -> rope -> unit
  (** [iter f rope] applies [f] on all characters of [rope] starting
      from the left. *)

val rev_iter : (Zed_char.t -> unit) -> rope -> unit
  (** [rev_iter f rope] applies [f] an all characters of [rope]
      starting from the right. *)

val fold : (Zed_char.t -> 'a -> 'a) -> rope -> 'a -> 'a
  (** [fold f rope acc] applies [f] on all characters of [rope]
      starting from the left, accumulating a value. *)

val rev_fold : (Zed_char.t -> 'a -> 'a) -> rope -> 'a -> 'a
  (** [rev_fold f rope acc] applies [f] on all characters of [rope]
      starting from the right, accumulating a value. *)

val map : (Zed_char.t -> Zed_char.t) -> rope -> rope
  (** [map f rope] maps all characters of [rope] with [f]. *)

val rev_map : (Zed_char.t -> Zed_char.t) -> rope -> rope
  (** [rev_map f str] maps all characters of [rope] with [f] in
      reverse order. *)

(** {5 Iteration and folding on leafs} *)

(** Note: for all of the following functions, the leaves must
    absolutely not be modified. *)

val iter_leaf : (Zed_string.t -> unit) -> rope -> unit
  (** [iter_leaf f rope] applies [f] on all leaves of [rope] starting
      from the left. *)

val rev_iter_leaf : (Zed_string.t -> unit) -> rope -> unit
  (** [iter_leaf f rope] applies [f] on all leaves of [rope] starting
      from the right. *)

val fold_leaf : (Zed_string.t -> 'a -> 'a) -> rope -> 'a -> 'a
  (** [fold f rope acc] applies [f] on all leaves of [rope] starting
      from the left, accumulating a value. *)

val rev_fold_leaf : (Zed_string.t -> 'a -> 'a) -> rope -> 'a -> 'a
  (** [rev_fold f rope acc] applies [f] on all leaves of [rope]
      starting from the right, accumulating a value. *)


val compare : rope -> rope -> int
  (** Compares two ropes (in code point order). *)

val equal : rope -> rope -> bool
  (** [equal r1 r2] retuns [true] if [r1] is equal to [r2]. *)

(** {5 Zippers} *)

module Zip : sig
  type t
    (** Type of zippers. A zipper allow to naviguate in a rope in a
        convenient and efficient manner. Note that a zipper points to
        a position between two glyphs, not to a glyph, so in a
        rope of length [len] there is [len + 1] positions. *)

  val make_f : rope -> int -> t
    (** [make_f rope pos] creates a new zipper pointing to positon
        [pos] of [rope]. *)

  val make_b : rope -> int -> t
    (** [make_b rope pos] creates a new zipper pointing to positon
        [length rope - pos] of [rope]. *)

  val offset : t -> int
    (** Returns the position of the zipper in the rope. *)

  val next : t -> Zed_char.t * t
    (** [next zipper] returns the glyph at the right of the
        zipper and a zipper to the next position. It raises
        [Out_of_bounds] if the zipper points to the end of the
        rope. *)

  val prev : t -> Zed_char.t * t
    (** [prev zipper] returns the glyph at the left of the
        zipper and a zipper to the previous position. It raises
        [Out_of_bounds] if the zipper points to the beginning of the
        rope. *)

  val move : int -> t -> t
    (** [move n zip] moves the zipper by [n] glyphs. If [n] is
        negative it is moved to the left and if it is positive it is
        moved to the right. It raises [Out_of_bounds] if the result
        is outside the bounds of the rope. *)

  val at_bos : t -> bool
    (** [at_bos zipper] returns [true] if [zipper] points to the
        beginning of the rope. *)

  val at_eos : t -> bool
    (** [at_eos zipper] returns [true] if [zipper] points to the
        end of the rope. *)

  val find_f : (Zed_char.t -> bool) -> t -> t
    (** [find_f f zip] search forward for a glyph to satisfy
        [f]. It returns a zipper pointing to the left of the first
        glyph to satisfy [f], or a zipper pointing to the end of
        the rope if no such glyph exists. *)

  val find_b : (Zed_char.t -> bool) -> t -> t
    (** [find_b f zip] search backward for a glyph to satisfy
        [f]. It returns a zipper pointing to the right of the first
        glyph to satisfy [f], or a zipper pointing to the
        beginning of the rope if no such glyph exists. *)

  val sub : t -> int -> rope
    (** [sub zipper len] returns the sub-rope of length [len] pointed
        by [zipper]. *)

  val slice : t -> t -> rope
    (** [slice zipper1 zipper2] returns the rope between [zipper1]
        and [zipper2]. If [zipper1 > zipper2] then this is the same as
        [slice zipper2 zipper1].

        The result is unspecified if the two zippers do not points to
        the same rope. *)
end

module Zip_raw : sig
  type t
    (** Type of zippers. A zipper allow to naviguate in a rope in a
        convenient and efficient manner. Note that a zipper points to
        a position between two characters, not to a character, so in a
        rope of length [len] there is [len + 1] positions. *)

  val make_f : rope -> int -> t
    (** [make_f rope pos] creates a new zipper pointing to raw positon
        [pos] of [rope]. *)

  val make_b : rope -> int -> t
    (** [make_b rope pos] creates a new zipper pointing to raw positon
        [length rope - pos] of [rope]. *)

  val offset : t -> int
    (** Returns the raw position of the zipper in the rope. *)

  val next : t -> Uchar.t * t
    (** [next zipper] returns the code point at the right of the
        zipper and a zipper to the next raw position. It raises
        [Out_of_bounds] if the zipper points to the end of the
        rope. *)

  val prev : t -> Uchar.t * t
    (** [prev zipper] returns the code point at the left of the
        zipper and a zipper to the previous raw position. It raises
        [Out_of_bounds] if the zipper points to the beginning of the
        rope. *)

  val move : int -> t -> t
    (** [move n zip] moves the zipper by [n] characters. If [n] is
        negative it is moved to the left and if it is positive it is
        moved to the right. It raises [Out_of_bounds] if the result
        is outside the bounds of the rope. *)

  val at_bos : t -> bool
    (** [at_bos zipper] returns [true] if [zipper] points to the
        beginning of the rope. *)

  val at_eos : t -> bool
    (** [at_eos zipper] returns [true] if [zipper] points to the
        end of the rope. *)

  val find_f : (Uchar.t -> bool) -> t -> t
    (** [find_f f zip] search forward for a character to satisfy
        [f]. It returns a zipper pointing to the left of the first
        character to satisfy [f], or a zipper pointing to the end of
        the rope if no such character exists. *)

  val find_b : (Uchar.t -> bool) -> t -> t
    (** [find_b f zip] search backward for a character to satisfy
        [f]. It returns a zipper pointing to the right of the first
        character to satisfy [f], or a zipper pointing to the
        beginning of the rope if no such character exists. *)
end

(** {5 Buffers} *)

module String_buffer = Buffer

module Buffer :
  sig
    type t
      (** Type of rope buffers. *)

    val create : unit -> t
      (** Create a new empty buffer. *)

    val add : t -> Zed_char.t -> unit
      (** [add buffer zChar] add [zChar] at the end of [buffer]. *)

    val add_uChar : t -> Uchar.t -> unit
      (** [add buffer uChar] add [uChar] at the end of [buffer]. *)

    val add_rope : t -> rope -> unit
      (** [add buffer rope] add [rope] at the end of [buffer]. *)

    val add_string : t -> Zed_string.t -> unit
      (** [add buffer str] add [str] at the end of [buffer]. *)

    val contents : t -> rope
      (** [contents buffer] returns the contents of [buffer] as a rope. *)

    val reset : t -> unit
      (** [reset buffer] resets [buffer] to its initial state. *)
  end
val init : int -> (int -> Zed_char.t) -> rope
val init_from_uChars : int -> (int -> Uchar.t) -> rope
val of_string : Zed_string.t -> rope
val to_string : rope -> Zed_string.t

val lowercase : ?locale:string -> t -> t
val uppercase : ?locale:string -> t -> t
