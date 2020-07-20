(*
 * lTerm_text.mli
 * --------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

(** Styled text. *)

type t = (Zed_char.t * LTerm_style.t) array
    (** Type of a string with styles for each characters. *)

(***)
val aval_width : Zed_string.width -> int

(** {6 Conversions} *)

val of_string : Zed_string.t -> t
  (** Creates a styled string from a string. All characters of the
      string have no style. *)

val to_string : t -> Zed_string.t
  (** Returns the string part of a styled string. *)

val of_utf8 : string -> t
  (** Creates a styled string from a utf8 string. All characters of the
      string have no style. *)

val of_string_maybe_invalid : Zed_string.t -> t
  (** Creates a styled string from a Zed_string. All characters of the
      string have no style. The string may contain invalid
      sequences, in which case invalid bytes are escaped with the
      syntax [\yXX]. *)

val of_utf8_maybe_invalid : string -> t
  (** Creates a styled string from a string. All characters of the
      string have no style. The string may contain invalid UTF-8
      sequences, in which case invalid bytes are escaped with the
      syntax [\yXX]. *)

val of_rope : Zed_rope.t -> t
  (** Creates a styled string from a rope. *)

val to_rope : t -> Zed_rope.t
  (** Returns the string part of a styled string as a rope. *)

val stylise : string -> LTerm_style.t -> t
  (** [stylise string style] creates a styled string with all styles
      set to [style]. *)

(** {6 Parenthesis matching} *)

val stylise_parenthesis : t -> ?paren : (Zed_char.t * Zed_char.t) list -> int -> LTerm_style.t -> unit
  (** [stylise_parenthesis text ?paren pos style] searchs for
      parenthesis group starting or ending at [pos] and apply them the
      style [style]. [paren] is the list of parenthesis recognized. *)

(** {6 Markup strings} *)

(** Markup strings are used to conveniently define styled strings. *)

(** Type of an item in a markup string. *)
type item =
  | S of Zed_utf8.t
      (** A UTF-8 encoded string. *)
  | R of Zed_rope.t
      (** A rope. *)
  | B_bold of bool
      (** Begins bold mode. *)
  | E_bold
      (** Ends bold mode. *)
  | B_underline of bool
      (** Begins underlined mode. *)
  | E_underline
      (** Ends underlined mode. *)
  | B_blink of bool
      (** Begins blinking mode. *)
  | E_blink
      (** Ends blinking mode. *)
  | B_reverse of bool
      (** Begins reverse video mode. *)
  | E_reverse
      (** Ends reverse video mode. *)
  | B_fg of LTerm_style.color
      (** Begins foreground color. *)
  | E_fg
      (** Ends foreground color. *)
  | B_bg of LTerm_style.color
      (** Begins background color. *)
  | E_bg
      (** Ends background color. *)

type markup = item list
    (** Type of a markup string. *)

val eval : markup -> t
  (** [eval makrup] evaluates a markup strings as a styled string. *)


(** {6 Styled formatters} *)

val make_formatter :
  ?read_color:(Format.tag -> LTerm_style.t) -> unit -> (unit -> t) * Format.formatter
(** Create a formatter on a styled string. Returns a tuple [get_content, fmt]. Calling [get_content ()] will flush the formatter and output the resulting styled string.

    If a [read_color] function is provided, Format's tag are enabled and [read_color] is used to transform tags into styles.
 *)

val pp_with_style :
  (LTerm_style.t -> Format.tag) ->
  (LTerm_style.t -> ('b, Format.formatter, unit, unit) format4 -> Format.formatter -> 'b)
(** [pp_with_style f] will create a pretty printer analogous to {!stylise}, using f to encode style into tags. Will only work on a formatter with tag enabled. *)

val styprintf :
  ?read_color:(Format.tag -> LTerm_style.t) ->
  ('a, Format.formatter, unit, t) format4 -> 'a
(** Equivalent of {!Format.sprintf} for styled strings. *)


val kstyprintf :
  ?read_color:(Format.tag -> LTerm_style.t) ->
  (t -> 'a) -> ('b, Format.formatter, unit, 'a) format4 -> 'b
(** Equivalent of {!Format.ksprintf} for styled strings. *)
