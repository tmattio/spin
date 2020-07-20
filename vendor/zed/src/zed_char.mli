(*
 * zed_char.mli
 * ------------
 * Copyright : (c) 2019, ZAN DoYe <zandoye@gmail.com>
 * Licence   : BSD3
 *
 * This file is a part of Zed, an editor engine.
 *)

open Result

(** The type for glyphs. *)
type t
(**
  To represent a grapheme in unicode is a bit more complicated than what
  is expected: a printable UChar. For example, diacritics are added to
  IPA(international phonetic alphabet) letter to produce a modified
  pronunciation. Variation selectors are added to a CJK character to
  specify a specific glyph variant for the character.

  Therefore the logical type definition of [Zed_char.t] can be seen as
  {[
    type Zed_char.t= {
      core: UChar.t;
      combined: UChar.t list;
    }
  ]}
  *)

type char_prop =
    Printable of int | Other | Null

  (** The property of a character. It can be either [Printable of width],
    [Other](unprintable character) or [Null](code 0). *)

val to_raw : t -> Uchar.t list
val to_array : t -> Uchar.t array

val core : t -> Uchar.t
  (** [core char] returns the core of the [char] *)

val combined : t -> Uchar.t list
  (** [combined char] returns the combining marks of the [char] *)

val unsafe_of_utf8 : string -> t
  (** [unsafe_of_utf8 str] returns a [zed_char] from utf8 encoded [str] without any validation. *)

val of_utf8 : ?indv_combining:bool -> string -> t
  (** [of_utf8 str] returns a [zed_char] from utf8 encoded [str].
    This function checks whether [str] represents a single [UChar] or a
    legal grapheme, i.e. a printable core with optional combining marks.
    It will raise [Failure "malformed Zed_char sequence"] If the validation
    is not passed.
    @param indv_combining allow to create a [Zed_char.t] from a single
    combining mark, default to [true]
   *)

val to_utf8 : t -> string
  (** [to_utf8 chr] converts a [chr] to a string encoded in UTF-8. *)

val zero : t
  (** The Character 0. *)

val prop_uChar : Uchar.t -> char_prop
  (** [prop_uChar uChar] returns the char_prop of [uChar] *)

val prop : t -> char_prop
  (** [prop ch] returns the char_prop of [ch] *)

val is_printable : Uchar.t -> bool
  (** Returns whether a [Uchar.t] is a printable character or not. *)

val is_printable_core : Uchar.t -> bool
  (** Returns whether a [Uchar.t] is a printable character and its width is not zero. *)

val is_combining_mark : Uchar.t -> bool
  (** Returns whether a [Uchar.t] is a combining mark. *)

val size : t -> int
  (** [size ch] returns the size (number of characters) of [ch]. *)

val length : t -> int
  (** Aliase of size *)

val width : t -> int
  (** [width ch] returns the width of [ch]. *)

val out_of_range : t -> int -> bool
  (** [out_of_range ch idx] returns whether [idx] is out of range of [ch]. *)

val get : t -> int -> Uchar.t
  (** [get ch n] returns the [n]-th character of [ch]. *)

val get_opt : t -> int -> Uchar.t option
  (** [get ch n] returns an optional value of the [n]-th character of [ch]. *)

val append : t -> Uchar.t -> t
  (** [append ch cm] append the combining mark [cm] to ch and returns it. If [cm] is not a combining mark, then the original [ch] is returned. *)

val compare_core : t -> t -> int
  (** [compare_core ch1 ch2] compares the core components of ch1 and ch2*)

val compare_raw : t -> t -> int
  (** [compare_raw ch1 ch2] compares over the internal characters of ch1 and ch2 sequentially *)

val compare : t -> t -> int
  (** Alias of compare_raw *)

val mix_uChar : t -> Uchar.t -> (t, t) result
  (** [mix_uChar chr uChar] tries to append [uChar] to [chr] and returns
    [Ok result]. If [uChar] is not a combining mark, then an
    [Error (Zed_char.t consists of uChar)] is returned. *)

val of_uChars : ?trim:bool -> ?indv_combining:bool -> Uchar.t list -> t option * Uchar.t list
  (** [of_uChars uChars] transforms [uChars] to a tuple. The first value
    is an optional [Zed_char.t] and the second is a list of remaining
    uChars. The optional [Zed_char.t] is either a legal grapheme(a core
    printable char with optinal combining marks) or a wrap for an
    arbitrary Uchar.t. After that, all remaining uChars returned as the
    second value in the tuple.
    @param trim trim leading combining marks before transforming, default to [false]
    @param indv_combining create a [Zed_char] from an individual dissociated combining mark, default to [true]
  *)

val zChars_of_uChars : ?trim:bool -> ?indv_combining:bool -> Uchar.t list -> t list * Uchar.t list
  (** [zChars of_uChars uChars] transforms [uChars] to a tuple. The first
    value is a list of [Zed_char.t] and the second is a list of remaining uChars.
    @param trim trim leading combining marks before transforming, default to [false]
    @param indv_combining create a [Zed_char] from an individual dissociated combining mark, default to [true]
  *)

val for_all : (Uchar.t -> bool) -> t -> bool
  (** [for_all p zChar] checks if all elements of [zChar]
   satisfy the predicate [p]. *)

val iter : (Uchar.t -> unit) -> t -> unit
  (** [iter f char] applies [f] on all characters of [char]. *)

(** The prefix 'unsafe_' of [unsafe_of_char] and [unsafe_of_uChar] means
  the two functions do not check if [char] or [uChar] being transformed
  is a valid grapheme. There is no 'safe_' version, because the scenario
  we should deal with a single [char] or [uChar] is when the char
  sequence are individual, incomplete. For example, when we are reading
  user input. Even if a user wants to input a legal grapheme, say,
  'a' with a hat(a combining mark) on top. the user will input 'a' and
  then '^' individually, the later combining mark is always illegal.
  What we should do is to invoke [unsafe_of_uChar user_input] and send
  the result to the edit engine. Other modules in zed, like Zed_string,
  Zed_lines, Zed_edit ... are already well designed to deal with such a
  situation. They will do combining mark joining, grapheme validation for
  you automatically. Use the two 'unsafe_' functions directly,
  you're doing things the right way. *)

val unsafe_of_char : char -> t
  (** [unsafe_of_char ch] returns a [Zed_char] whose core is [ch]. *)

val unsafe_of_uChar : Uchar.t -> t
  (** [unsafe_of_uChar ch] returns a [Zed_char] whose core is [ch]. *)