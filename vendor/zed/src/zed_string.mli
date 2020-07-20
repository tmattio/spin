(*
 * zed_string.mli
 * -----------
 * Copyright : (c) 2019, ZAN DoYe <zandoye@gmail.com>
 * Licence   : BSD3
 *
 * This file is a part of Zed, an editor engine.
 *)

open Result

exception Invalid of string * string
  (** [Invalid (error, text)] Exception raised when an invalid Zed_char
      sequence is encountered. [text] is the faulty text and
      [error] is a description of the first error in [text]. *)

exception Out_of_bounds
  (** Exception raised when trying to access a character which is
      outside the bounds of a string. *)

type seg_width = { start : int; len : int; width : int; }
  (** Type of the width of a segment of a Zed_string.t *)

type all_width = { len : int; width : int; }
  (** Type of the width of a whole Zed_string.t *)

type width = (all_width, seg_width) result
  (** Type of the width of a Zed_string.t *)

type t
  (** Type of Zed_string.t *)

val unsafe_of_utf8 : string -> t
  (** Create a Zed_string.t from a utf8 encoded string. *)

val of_utf8 : string -> t
  (** Create a Zed_string.t from a utf8 encoded string and check whether it's well formed.
    @raise Invalid
    @raise Zed_utf8.Invalid
   *)

val to_utf8 : t -> string
  (** Create a utf8 encoded string from a Zed_string.t. *)

val explode : t -> Zed_char.t list
  (** [explode str] returns the list of all Zed_char.t of [str]. *)

val rev_explode : t -> Zed_char.t list
  (** [explode str] returns the list of all Zed_char.t of [str] in reverse order. *)

val unsafe_explode : t -> Zed_char.t list
  (** [explode str] returns the list of all Zed_char.t of [str] even if [str] is malformed. *)

val unsafe_rev_explode : t -> Zed_char.t list
  (** [explode str] returns the list of all Zed_char.t of [str] in reverse order even if [str] is malformed. *)

val implode : Zed_char.t list -> t
  (** [implode l] returns the concatenation of all Zed_char.t of [l]. *)

val aval_width : width -> int
  (** Returns the widest available width *)

val init : int -> (int -> Zed_char.t) -> t
  (** [init n f] returns the contenation of [implode [(f 0)]],
      [implode [(f 1)]], ..., [implode [(f (n - 1))]]. *)

val init_from_uChars : int -> (int -> Uchar.t) -> t
  (** [init n f] creates a sequence of Uchar.t of [f 0], [f 1], ..., [f (n-1)] and implode the contenation of it. *)

val make : int -> Zed_char.t -> t
  (** [make n ch] creates a Zed_string.t of length [n] filled with [ch]. *)

val copy : t -> t
  (** [copy s] returns a copy of [s], that is, a fresh Zed_string.t containing the same elements as [s]. *)

val to_raw_list : t -> Uchar.t list
  (** Same as explode, but the elements in the list is [Uchar.t]. *)

val to_raw_array : t -> Uchar.t array
  (** Same as explode, but the elements in the array is [Uchar.t]. *)

type index = int
val get : t -> int -> Zed_char.t
  (** [get str idx] returns the Zed_char.t at index [idx] in [str]. *)

val get_raw : t -> int -> Uchar.t
  (** [get_raw str idx] returns the Uchar.t at Uchar.t based index [idx] in [str]. *)

val empty : unit -> t
  (** [empty ()] creates an empty Zed_string.t. *)

val width_ofs : ?start:index -> ?num:int -> t -> width
(** [width_ofs ?start ?num str] returns the [width] of a Zed_string.t that starts at offset [start] and has length less than [num]. *)

val width : ?start:int -> ?num:int -> t -> width
(** [width ?start ?num str] returns the [width] of a Zed_string.t that starts at positon [start] and has length less than [num]. *)

val bytes : t -> index
  (** [bytes str] returns the number of bytes in [str]. It's also the index point to the end of [str]. *)

val size : t -> int
  (** [size str] returns the number of Uchar.t in [str]. *)

val length : t -> int
  (** [length str] returns the number of Zed_char.t in [str] *)

val next_ofs : t -> int -> int
  (** [next_ofs str ofs] returns the offset of the next zed_char in [str]. *)

val prev_ofs : t -> int -> int
  (** [prev_ofs str ofs] returns the offset of the previous zed_char in [str]. *)

val extract : t -> index -> Zed_char.t
  (** [extract str ofs] returns the Zed_char.t at offset [ofs] in [str]. *)

val extract_next : t -> index -> (Zed_char.t * index)
  (** [extract_next str ofs] returns the Zed_char.t at offset [ofs] in [str] and the offset of the next Zed_char.t *)

val extract_prev : t -> index -> (Zed_char.t * index)
  (** [extract_prev str ofs] returns the Zed_char.t at the previous offset [ofs] in [str] and this offset. *)

val unsafe_of_uChars : Uchar.t list -> t
  (** [unsafe_of_uChars l] returns the concatenation of all Uchar.t of [l]. *)

val of_uChars : Uchar.t list -> t * Uchar.t list
  (** [of_uChars l] returns a tuple of which the first element is a well formed Zed_string.t concatenating of all Uchar.t of [l] and the second element is a list of the remaining Uchar.t. *)

val for_all : (Zed_char.t -> bool) -> t -> bool
  (** [for_all p zStr] checks if all Zed_char.t in [zStr]
   satisfy the predicate [p]. *)


val iter : (Zed_char.t -> unit) -> t -> unit
  (** [iter f str] applies [f] an all characters of [str] starting from the left. *)

val rev_iter : (Zed_char.t -> unit) -> t -> unit
  (** [iter f str] applies [f] an all characters of [str] starting from the right. *)

val fold : (Zed_char.t -> 'a -> 'a) -> t -> 'a -> 'a
  (** [fold f str acc] applies [f] on all characters of [str] starting from the left, accumulating a value. *)

val rev_fold : (Zed_char.t -> 'a -> 'a) -> t -> 'a -> 'a
  (** [fold f str acc] applies [f] on all characters of [str] starting from the right, accumulating a value. *)

val map : (Zed_char.t -> Zed_char.t) -> t -> t
  (** [map f str] maps all characters of [str] with [f]. *)

val rev_map : (Zed_char.t -> Zed_char.t) -> t -> t
  (** [map f str] maps all characters of [str] with [f] in reverse order. *)


val check_range : t -> int -> bool
val look : t -> index -> Uchar.t
  (** [look str idx] returns the character in the location [idx] of [str]. *)

val nth : t -> int -> index
  (** [nth str n] returns the location of the [n]-th character in [str]. *)

(**  [next str i], [prev str i] The operation is valid if [i] points the valid element, i.e. the returned value may point the location beyond valid elements by one. If i does not point a valid element, the results are unspecified. *)

val next : t -> index -> index
  (** [next str idx] returns the index of the next zed_char in [str]. *)

val prev : t -> index -> index
  (** [prev str idx] returns the index of the previous zed_char in [str]. *)

val out_of_range : t -> index -> bool
val compare : t -> t -> int
  (** Compares two strings by [Zed_char.compare]. *)

val first : t -> index
  (** [first str] returns the location of the first character in [str]. *)

val last : t -> index
  (** [last str] returns the location of the last character in [str]. *)

val move : t -> index -> int -> index
  (**  [move str i n] if n >= 0, then returns [n]-th character after [i] and otherwise returns -[n]-th character before [i.] If there is no such character, or [i] does not point a valid character, the result is unspecified. *)

val move_raw : t -> index -> int -> index
  (**  [move_raw str i n] if n >= 0, then returns [n]-th Uchar.t after [i] and otherwise returns -[n]-th Uchar.t before [i.] If there is no such Uchar.t, or [i] does not point a valid Uchar.t, the result is unspecified. *)

val compare_index : t -> index -> index -> int
  (**  [compare_index str i j] returns a positive integer if [i] is the location placed after [j] in [str], 0 if [i] and [j] point the same location, and a negative integer if [i] is the location placed before [j] in [str]. *)

val sub_ofs : ofs:index -> len:int -> t -> t
  (** [sub_ofs ofs len str] returns the sub-string of [str] starting at byte-offset [ofs] and of byte-length [len]. *)

val sub : pos:int -> len:int -> t -> t
  (** [sub ~pos ~len str] returns the sub-string of [str] starting at position [pos] and of length [len]. *)

val after : t -> int -> t
  (** [after str pos] returns the sub-string after [pos] in [str] *)

val unsafe_sub_equal : t -> int -> t -> int -> bool
val starts_with : prefix:t -> t -> bool
  (** [starts_with ~prefix str] returns [true] if [str] starts with [prefix]. *)

val ends_with : suffix:t -> t -> bool
  (** [ends_with ~suffix str] returns [true] if [str] ends with [suffix]. *)

val unsafe_append : t -> t -> t
  (** [unsafe_append str1 str2] returns the concatenation of [str1] and [str2] without sequence validation. *)

val append : t -> t -> t
  (** [append str1 str2] returns the concatenation of [str1] and [str2].
    @raise Invalid
    @raise Zed_utf8.Invalid
   *)

module Buf :
  sig
    type buf
      (** Type of Zed_string buffers. *)

    val create : int -> buf
      (** Create a new empty buffer. *)

    val contents : buf -> t
      (** [contents buffer] returns the contents of [buffer] as a Zed_string.t. *)

    val clear : buf -> unit
      (** [clear buffer] clear the contents of [buffer]. *)

    val reset : buf -> unit
      (** [reset buffer] resets [buffer] to its initial state. *)

    val length : buf -> int
      (** [length buffer] returns the length of the contents in [buffer] *)

    val add_zChar : buf -> Zed_char.t -> unit
      (** [add buffer zChar] add [zChar] at the end of [buffer]. *)

    val add_uChar : buf -> Uchar.t -> unit
      (** [add buffer uChar] add [uChar] at the end of [buffer]. *)

    val add_string : buf -> t -> unit
      (** [add buffer str] add [str] at the end of [buffer]. *)

    val add_buffer : buf -> buf -> unit
      (** [add buffer buf] add [buf] at the end of [buffer]. *)
  end

