(*
 * zed_edit.mli
 * ------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Zed, an editor engine.
 *)

(** Edition engines *)

open React

type 'a t
  (** Type of edition engines. ['a] is the type of custom data
      attached to the engine in order to extend it. *)

(** Type of clipboards. *)
type clipboard = {
  clipboard_get : unit -> Zed_rope.t;
  (** Returns the current contents of the clipboard. *)
  clipboard_set : Zed_rope.t -> unit;
  (** Sets the contents of the clipboard. *)
}

val new_clipboard : unit -> clipboard
  (** [new_clipboard ()] creates a new clipboard using a reference. *)

val create :
  ?editable : (int -> int -> bool) ->
  ?move : (int -> int -> int) ->
  ?clipboard : clipboard ->
  ?match_word : (Zed_rope.t -> int -> int option) ->
  ?locale : string option signal ->
  ?undo_size : int ->
  unit -> 'a t
  (** [create ?editable ?move ?clipboard ()] creates a new edition
      engine in the initial state.

      [editable] is used to determine whether the text at given
      position is editable or not. It takes as argument the position
      and the length of the text to remove.

      [move] is unused.

      [clipboard] is the clipboard to use for this engine. If none is
      defined, a new one using a reference is created.

      [match_word] is used to recognize words. It must returns the end
      of the matched word if any.

      [locale] is the locale of this buffer. It is used for case
      mapping.

      [undo_size] is the size of the undo buffer. It is the number of
      state zed will remember. It defaults to [1000]. *)


val get_data : 'a t -> 'a
  (** [get_data edit] returns the custom data attached to the
      engine. It raises [Not_found] if no data is attached to the
      engine. *)

val set_data : 'a t -> 'a -> unit
  (** [set_data edit data] attach [data] to the engine. *)

val clear_data : 'a t -> unit
  (** [clear_data edit] removes the custom data of engine. *)

val text : 'a t -> Zed_rope.t
  (** [text edit] returns the signal holding the current contents of
      the buffer. *)

val lines : 'a t -> Zed_lines.t
  (** [lines edit] returns the set of line position of [text edit]. *)

val get_line : 'a t -> int -> Zed_rope.t
  (** [get_line edit n] returns the rope corresponding to the [n]th line
      without the newline character. *)

val changes : 'a t -> Zed_cursor.changes  event
  (** [changes edit] returns an event which occurs with values of the
      form [(start, added, removed)] when the contents of the engine
      changes. [start] is the start of modifications, [added] is the
      number of characters added and [removed] is the number of
      characters removed. *)

val update : 'a t -> Zed_cursor.t list -> unit event
  (** [update edit cursors] returns an event which occurs each the
      rendering of the engine should be updated. *)

val erase_mode : 'a t -> bool signal
  (** [erase_mode edit] returns the ``erase'' mode of the buffer. In
      this mode character inserted in the buffer erase existing
      ones. *)

val get_erase_mode : 'a t -> bool
  (** [erase_mode edit] returns the current erase mode of the
      buffer. *)

val set_erase_mode : 'a t -> bool -> unit
  (** [set_erase_mode edit state] sets the status of the erase mode
      for the given engine. *)

val mark : 'a t -> Zed_cursor.t
  (** [mark edit] returns the cursor used to for the mark in the given
      engine. *)

val selection : 'a t -> bool signal
  (** [selection edit] returns the signal holding the current
      selection state. If [true], text is being selectionned. *)

val get_selection : 'a t -> bool
  (** [selection edit] returns the current selection state. *)

val set_selection : 'a t -> bool -> unit
  (** [set_selection edit state] sets the selection state. *)

(** {5 Cursors} *)

val new_cursor : 'a t -> Zed_cursor.t
  (** [new_cursor edit] creates a new cursor for the given edition
      engine. The cursor initially points to the beginning of the
      buffer. *)

(** {5 Actions} *)

exception Cannot_edit
  (** Exception raised when trying to edit a non-editable portion of a
      buffer. *)

type 'a context
  (** Type of contexts. Contexts are used to modify an edition
      buffer. *)

val context : ?check : bool -> 'a t -> Zed_cursor.t -> 'a context
  (** [context ?check edit cursor] creates a new context with given
      parameters. [cursor] is the cursor that will be used for all
      modification of the text. If [check] is [true] (the default)
      then all modification of the text will be checked with the
      [editable] function of the engine. *)

val edit : 'a context -> 'a t
  (** [edit ctx] returns the edition engine used by the given
      context. *)

val cursor : 'a context -> Zed_cursor.t
  (** [cursor ctx] returns the cursor used by this context. *)

val check : 'a context -> bool
  (** [check ctx] returns whether the context has been created with
      the [check] flag. *)

val with_check : bool -> 'a context -> 'a context
  (** [with_check check ctx] retuns [ctx] with the check flag set to
      [check]. *)

val goto : 'a context -> ?set_wanted_column : bool -> int -> unit
  (** [goto ctx ?set_column position] moves the cursor to the given
      position. It raises {!Zed_cursor.Out_of_bounds} if the position
      is outside the bounds of the text. If [set_wanted_column] is
      [true], the wanted column of the cursor is set to the new
      column. *)

val move : 'a context -> ?set_wanted_column : bool -> int -> unit
  (** [move ctx ?set_wanted_column delta] moves the cursor by the
      given number of characters. It raises
      {!Zed_cursor.Out_of_bounds} if the current plus [delta] is
      outside the bounds of the text. *)

val move_line : 'a context -> int -> unit
  (** [move_line ctx ?set_wanted_column delta] moves the cursor by the
      given number of lines. *)

val position : 'a context -> int
  (** [position ctx] returns the position of the cursor. *)

val line : 'a context -> int
  (** [line ctx] returns the line of the cursor. *)

val column : 'a context -> int
  (** [column ctx] returns the column of the cursor. *)

val column_display : 'a context -> int
  (** [column_display ctx] returns the display column of the cursor. *)

val at_bol : 'a context -> bool
  (** [at_bol ctx] returns [true] iff the cursor is at the beginning
      of the current line. *)

val at_eol : 'a context -> bool
  (** [at_eol ctx] returns [true] iff the cursor is at the end of the
      current line. *)

val at_bot : 'a context -> bool
  (** [at_bot ctx] returns [true] iff the cursor is at the beginning
      of the text. *)

val at_eot : 'a context -> bool
  (** [at_eot ctx] returns [true] iff the cursor is at the end of the
      text. *)

val insert : 'a context -> Zed_rope.t -> unit
  (** [insert ctx rope] inserts the given rope at current position. *)

val insert_char : 'a context -> Uchar.t -> unit
  (** [insert ctx rope] inserts the given Uchar at current position. *)

val insert_no_erase : 'a context -> Zed_rope.t -> unit
  (** [insert ctx rope] inserts the given rope at current position but
      do not erase text if the buffer is currently in erase mode. *)

val remove_next : 'a context -> int -> unit
  (** [remove_next ctx n] removes [n] characters at current
      position. If there is less than [n] characters at current
      position, it removes everything until the end of the text. *)

val remove_prev : 'a context -> int -> unit
  (** [remove_prev ctx n] removes [n] characters before current
      position. If there is less than [n] characters before current
      position, it removes everything until the beginning of the
      text. *)

val remove : 'a context -> int -> unit
  (** Alias for {!remove_next} *)

val replace : 'a context -> int -> Zed_rope.t -> unit
  (** [replace ctx n rope] does the same as:

      {[
        remove ctx n;
        insert_no_erase ctx rope
      ]}

      but in one atomic operation. *)

val newline : 'a context -> unit
  (** Insert a newline character. *)

val next_char : 'a context -> unit
  (** [next_char ctx] moves the cursor to the next character. It does
      nothing if the cursor is at the end of the text. *)

val prev_char : 'a context -> unit
  (** [prev_char ctx] moves the cursor to the previous character. It
      does nothing if the cursor is at the beginning of the text. *)

val next_line : 'a context -> unit
  (** [next_line ctx] moves the cursor to the next line. If the cursor
      is on the last line, it is moved to the end of the buffer. *)

val prev_line : 'a context -> unit
  (** [prev_line ctx] moves the cursor to the previous line. If the
      cursor is on the first line, it is moved to the beginning of the
      buffer. *)

val goto_bol : 'a context -> unit
  (** [goto_bol ctx] moves the cursor to the beginning of the current
      line. *)

val goto_eol : 'a context -> unit
  (** [goto_eol ctx] moves the cursor to the end of the current
      line. *)

val goto_bot : 'a context -> unit
  (** [goto_bot ctx] moves the cursor to the beginning of the text. *)

val goto_eot : 'a context -> unit
  (** [goto_eot ctx] moves the cursor to the end of the text. *)

val delete_next_char : 'a context -> unit
  (** [delete_next_char ctx] deletes the character after the cursor,
      if any. *)

val delete_prev_char : 'a context -> unit
  (** [delete_prev_char ctx] delete the character before the
      cursor. *)

val delete_next_line : 'a context -> unit
  (** [delete_next_line ctx] delete everything until the end of the
      current line. *)

val delete_prev_line : 'a context -> unit
  (** [delete_next_line ctx] delete everything until the beginning of
      the current line. *)

val kill_next_line : 'a context -> unit
  (** [kill_next_line ctx] delete everything until the end of the
      current line and save it to the clipboard. *)

val kill_prev_line : 'a context -> unit
  (** [kill_next_line ctx] delete everything until the beginning of
      the current line and save it to the clipboard. *)

val switch_erase_mode : 'a context -> unit
  (** [switch_erase_mode ctx] switch the current erase mode. *)

val set_mark : 'a context -> unit
  (** [set_mark ctx] sets the mark at current position. *)

val goto_mark : 'a context -> unit
  (** [goto_mark ctx] moves the cursor to the mark. *)

val copy : 'a context -> unit
  (** [copy ctx] copies the current selectionned region to the
      clipboard. *)

val copy_sequence: 'a context -> int -> int -> unit
  (** [copy_sequence ctx start len] copies [len] characters start
      from [start] to the clipboard. *)

val kill : 'a context -> unit
  (** [kill ctx] copies the current selectionned region to the
      clipboard and remove it. *)

val yank : 'a context -> unit
  (** [yank ctx] inserts the contents of the clipboard at current
      position. *)

val capitalize_word : 'a context -> unit
  (** [capitalize_word ctx] capitalizes the first word after the
      cursor. *)

val lowercase_word : 'a context -> unit
  (** [lowercase_word ctx] converts the first word after the cursor to
      lowercase. *)

val uppercase_word : 'a context -> unit
  (** [uppercase_word ctx] converts the first word after the cursor to
      uppercase. *)

val next_word : 'a context -> unit
  (** [next_word ctx] moves the cursor to the end of the next word. *)

val prev_word : 'a context -> unit
  (** [prev_word ctx] moves the cursor to the beginning of the
      previous word. *)

val delete_next_word : 'a context -> unit
  (** [delete_next_word ctx] deletes the word after the cursor. *)

val delete_prev_word : 'a context -> unit
  (** [delete_prev_word ctx] deletes the word before the cursor. *)

val kill_next_word : 'a context -> unit
  (** [kill_next_word ctx] deletes the word after the cursor and save
      it to the clipboard. *)

val kill_prev_word : 'a context -> unit
  (** [kill_prev_word ctx] deletes the word before the cursor and save
      it to the clipboard. *)

val undo : 'a context -> unit
  (** [undo ctx] reverts the last performed action. *)

(** {5 Action by names} *)

(** Type of actions. *)
type action =
  | Insert of Zed_char.t
  | Insert_str of Zed_string.t
  | Newline
  | Next_char
  | Prev_char
  | Next_line
  | Prev_line
  | Join_line
  | Set_pos of int
  | Goto of int
  | Goto_bol
  | Goto_eol
  | Goto_bot
  | Goto_eot
  | Delete_next_chars of int
  | Delete_prev_chars of int
  | Kill_next_chars of int
  | Kill_prev_chars of int
  | Delete_next_char
  | Delete_prev_char
  | Delete_next_line
  | Delete_prev_line
  | Kill_next_line
  | Kill_prev_line
  | Switch_erase_mode
  | Set_mark
  | Goto_mark
  | Copy
  | Kill
  | Yank
  | Capitalize_word
  | Lowercase_word
  | Uppercase_word
  | Next_word
  | Prev_word
  | Delete_next_word
  | Delete_prev_word
  | Kill_next_word
  | Kill_prev_word
  | Undo

val get_action : action -> ('a context -> unit)
  (** [get_action action] returns the function associated to the given
      action. *)

val actions : (action * string) list
  (** List of actions with their names, except {!Insert}. *)

val doc_of_action : action -> string
  (** [doc_of_action action] returns a short description of the
      action. *)

val action_of_name : string -> action
  (** [action_of_name str] converts the given action name into an
      action. Action name are the same as function name but with '_'
      replaced by '-', number parameter replaced with "(number)".
      It raises [Not_found] if the name does not correspond to an action.

      [Insert ch] is represented by "insert(<char>)" where [<char>] is:

      - a literal ascii character, such as "a", "b", ...
      - a unicode character, written "U+< code >", such as "U+0041"

      [Insert_str str] is represented by "insert-str(<str>)" where
      [<str>] is raw utf8 string.
  *)

val name_of_action : action -> string
  (** [name_of_action act] returns the name of the given action. *)
