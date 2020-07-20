(*
 * lTerm.mli
 * ---------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

(** Terminal definitions *)

type t
  (** Type of terminals. *)

(** {6 Creation} *)

exception No_such_encoding of string
  (** Exception raised when an encoding does not exist. *)

val create :
  ?windows : bool ->
  ?model : string ->
  Lwt_unix.file_descr -> Lwt_io.input_channel ->
  Lwt_unix.file_descr -> Lwt_io.output_channel -> t Lwt.t
  (** [create ?windows ?model ?incoming_encoding ?outgoing_encoding
      input_fd input_channel outout_fd output_channel] creates a new
      terminal using [input_fd] and [input_channel] for inputs and
      [output_fd] and [output_channel] for outputs.

      - [windows] indicates whether the terminal is a windows console
      (not mintty, rxvt, ...). It defaults to [Sys.win32].

      - [model] is the type of the terminal, such as "rxvt" or
      "xterm". It defaults to the contents of the "TERM" environment
      variable, or to "dumb" if this one is not found. It is used to
      determine capabilities of the terminal, such as the number of
      colors. This is not used if [windows] is [true].

      - [incoming_encoding] is the encoding used for incoming data. It
      defaults to [LTerm_windows.get_console_cp] if [windows] is [true]
      and [LTerm_unix.system_encoding] otherwise.

      - [outgoing_encoding] is the encoding used for outgoing data. It
      defaults to [LTerm_windows.get_console_output_cp] if [windows] is
      [true] and [LTerm_unix.system_encoding] otherwise. Note that
      transliteration is used so printing unicode character on the
      terminal will never fail.

      If one of the two given encodings does not exist, it raises
      [No_such_encoding].

      Note about terminal resize: in the windows console resizes are
      not automatically detected. Lambda-term will only check for
      resize only when something happens. If you want it to poll just
      write somewhere in your program:

      {[
      Lwt_engine.on_timer 1.0 true ignore
      ]}
  *)

(** {6 Informations} *)

val model : t -> string
  (** Returns the model of the terminal. *)

val colors : t -> int
  (** Number of colors of the terminal. *)

val windows : t -> bool
  (** Whether the terminal is a windows console or not. *)

val is_a_tty : t -> bool
  (** [is_a_tty term] whether the intput and output of the given
      terminal are connected to a tty device. *)

val incoming_is_a_tty : t -> bool
  (** [incoming_is_a_tty term] whether the input of [term] is a tty
      device. *)

val outgoing_is_a_tty : t -> bool
  (** [incoming_is_a_tty term] whether the output of [term] is a tty
      device. *)

val escape_time : t -> float
  (** Time waited before returning the escape key. This is not used on
      windows. *)

val set_escape_time : t -> float -> unit
  (** Set the time waited before returning the escape key. *)

exception Not_a_tty
  (** Exception raised when trying to use a function that can only be
      used on terminals. *)

val size : t -> LTerm_geom.size
  (** Returns the curent size of the terminal.

      It raises {!Not_a_tty} if the output of the given terminal is
      not a tty. *)

(** {6 Modes} *)

type mode
  (** Type of terminal modes. *)

val enter_raw_mode : t -> mode Lwt.t
  (** [enter_raw_mode term] puts the terminal in ``raw mode''. In this
      mode keyboard events are returned as they happen. In normal mode
      only complete line are returned. It returns the current terminal
      mode that can be restored using {!leave_raw_mode}.

      It raises {!Not_a_tty} if the input of the given terminal is not
      tty. *)

val leave_raw_mode : t -> mode -> unit Lwt.t
  (** [leave_raw_mode term mode] leaves the raw mode by restoring the
      given mode.

      It raises {!Not_a_tty} if the input of the given terminal is not
      tty. *)

val enable_mouse : t -> unit Lwt.t
  (** Enable mouse events reporting.

      It raises {!Not_a_tty} if the output of the given terminal is
      not a tty. *)

val disable_mouse : t -> unit Lwt.t
  (** Disable mouse events reporting.

      It raises {!Not_a_tty} if the output of the given terminal is
      not a tty. *)

(** {6 Cursor} *)

val show_cursor : t -> unit Lwt.t
  (** Make the cursor visible.

      It raises {!Not_a_tty} if the output of the given terminal is
      not a tty. *)

val hide_cursor : t -> unit Lwt.t
  (** Make the cursor invisible.

      It raises {!Not_a_tty} if the output of the given terminal is
      not a tty. *)

val goto : t -> LTerm_geom.coord -> unit Lwt.t
  (** [goto term coord] moves the cursor to the given coordinates.

      It raises {!Not_a_tty} if the output of the given terminal is
      not a tty. *)

val move : t -> int -> int -> unit Lwt.t
  (** [move term rows columns] moves the cursor by the given number of
      lines and columns. Both [rows] and [columns] may be negavite.

      It raises {!Not_a_tty} if the output of the given terminal is
      not a tty. *)

(** {6 Erasing text} *)

val clear_screen : t -> unit Lwt.t
  (** [clear_screen term] clears the entire screen. *)

val clear_screen_next : t -> unit Lwt.t
  (** [clear_screen_next term] clears the screen from the cursor to
      the bottom of the screen. *)

val clear_screen_prev : t -> unit Lwt.t
  (** [clear_screen_prev term] clears the screen from the cursor to
      the top of the screen. *)

val clear_line : t -> unit Lwt.t
  (** [clear_line term] erases the current line. *)

val clear_line_next : t -> unit Lwt.t
  (** [clear_line_next term] erases the current line from the cursor
      to the end of the line. *)

val clear_line_prev : t -> unit Lwt.t
  (** [clear_line_prev term] erases the current line from the cursor
      to the beginning of the line. *)

(** {6 State} *)

val save_state : t -> unit Lwt.t
  (** Save the current state of the terminal so it can be restored
      latter.

      It raises {!Not_a_tty} if the output of the given terminal is
      not a tty. *)

val load_state : t -> unit Lwt.t
  (** Load the previously saved state of the terminal.

      It raises {!Not_a_tty} if the output of the given terminal is
      not a tty. *)

(** {6 Events} *)

val read_event : t -> LTerm_event.t Lwt.t
  (** Reads and returns one event. The terminal should be in raw mode
      before calling this function, otherwise event will not be
      reported as they happen. It does not fail if the terminal is not
      a tty.

      Note: you must not call {!read_event} from multiple thread at
      the same time, it will raise {!Failure} if you try to do so. *)

(** {6 Printing} *)

(** All these functions accept only valid UTF-8 strings (or unicode
    styled text). Strings are recoded on the fly using the terminal
    output encoding (except if the terminal output encoding is already
    UTF-8, in which case the string is just printed as-it).

    The general name of a printing function is [<prefix>print<suffixes>].

    Where [<prefix>] is one of:
    - ['f'], which means that the function takes as argument a terminal
    - nothing, which means that the function prints on {!stdout}
    - ['e'], which means that the function prints on {!stderr}

    and [<suffixes>] is a combination of:
    - ['l'] which means that a new-line character is printed after the message
    - ['f'] which means that the function takes as argument a {b format} instead
      of a string
    - ['s'] which means that the function takes as argument a styled
      string instead of a string

    Note that if the terminal is not a tty, styles are stripped.
*)

val fprint : t -> Zed_utf8.t -> unit Lwt.t
val fprintl : t -> Zed_utf8.t -> unit Lwt.t
val fprintf : t -> ('a, unit, Zed_utf8.t, unit Lwt.t) format4 -> 'a
val fprints : t -> LTerm_text.t -> unit Lwt.t
val fprintlf : t -> ('a, unit, Zed_utf8.t, unit Lwt.t) format4 -> 'a
val fprintls : t -> LTerm_text.t -> unit Lwt.t
val print : Zed_utf8.t -> unit Lwt.t
val printl : Zed_utf8.t -> unit Lwt.t
val printf : ('a, unit, Zed_utf8.t, unit Lwt.t) format4 -> 'a
val prints : LTerm_text.t -> unit Lwt.t
val printlf : ('a, unit, Zed_utf8.t, unit Lwt.t) format4 -> 'a
val printls : LTerm_text.t -> unit Lwt.t
val eprint : Zed_utf8.t -> unit Lwt.t
val eprintl : Zed_utf8.t -> unit Lwt.t
val eprintf : ('a, unit, Zed_utf8.t, unit Lwt.t) format4 -> 'a
val eprints : LTerm_text.t -> unit Lwt.t
val eprintlf : ('a, unit, Zed_utf8.t, unit Lwt.t) format4 -> 'a
val eprintls : LTerm_text.t -> unit Lwt.t

(** {8 Printing contexts} *)

(** You shoud use these functions when you to print a lot of styled
    text that does not entirely fit in a single {!LTerm_text.t}
    value.

    This is more efficient than calling manually {!set_style} since
    styles will be modified only when needed. *)

type context
  (** A context for styled printing. *)

val with_context : t -> (context -> 'a Lwt.t) -> 'a Lwt.t
  (** [with_context term f] creates a new printing context and pass it
      to [f]. Note that calls to [with_context] are serialized. *)

val update_style : context -> LTerm_style.t -> unit Lwt.t
  (** [update_style ctx style] updates the style of the context with
      [style]. If needed styles of the terminal are modified. *)

val context_term : context -> t
  (** Returns the terminal used by the given context. *)

val context_oc : context -> Lwt_io.output_channel
  (** Returns the output channel used by the given context. Note that
      this channel cannot be used after {!with_context} has
      terminated. *)

val encode_string : Zed_utf8.t -> string
  (** [encode_string term str] encodes an UTF-8 string using the
      terminal encoding. *)

val encode_char : Uchar.t -> string
  (** [encode_char term ch] encodes an unicode character using the
      terminal encoding. *)

(** {6 Styles} *)

val set_style : t -> LTerm_style.t -> unit Lwt.t
  (** Change the style of the termina for subsequent unstyled
      output. It does nothing if the output is not a tty. *)

(** {6 Rendering} *)

val render : t -> LTerm_draw.matrix -> unit Lwt.t
  (** Render an offscreen array to the given terminal.

      It raises {!Not_a_tty} if the output of the given terminal is
      not a tty. *)

val render_update : t -> LTerm_draw.matrix -> LTerm_draw.matrix -> unit Lwt.t
  (** [render_update displayed to_display] does the same as [render
      to_display] but assumes that [displayed] contains the current
      displayed text. This reduces the amount of text sent to the
      terminal.

      It raises {!Not_a_tty} if the output of the given terminal is
      not a tty. *)

val print_box : t -> LTerm_draw.matrix -> unit Lwt.t
  (** [print_box term matrix] prints the contents of [matrix] starting
      at current cursor row. Note that when you have the choice
      between using {!fprints} and {!print_box} you should use
      {!print_box} because it works better under windows and is more
      efficient.

      The cursor is moved to the beginning of the last displayed
      line. *)

val print_box_with_newlines : t -> LTerm_draw.matrix -> unit Lwt.t
  (** [print_box term matrix] Same as {!print_box} but [matrix]
      may contains newline characters. It must contain one more column
      that the terminal (in case a line of the length of the terminal
      ends with a newline).

      The difference between {!print_box} and
      {!print_box_with_newlines} is that when the text is selected in
      the terminal, with {!print_box} it will always be a box with the
      dimensions of [matrix]. With {!print_box_with_newlines} it may
      contains lines longer than the width of the terminal.

      The contents of a line after the first newline character (if
      any) in a row of [matrix] is ignored. The rest of the line get
      the style of the newline character. *)

(** {6 Misc} *)

val flush : t -> unit Lwt.t
  (** Flushes the underlying output channel used by the terminal. *)

(** {6 Well known instances} *)

val stdout : t Lwt.t Lazy.t
  (** Terminal using {!Lwt_unix.stdin} as input and {!Lwt_unix.stdout}
      as output. *)

val stderr : t Lwt.t Lazy.t
  (** Terminal using {!Lwt_unix.stdin} as input and {!Lwt_unix.stderr}
      as output. *)

(** {6 Low-level functions} *)

val get_size_from_fd : Lwt_unix.file_descr -> LTerm_geom.size Lwt.t
  (** [get_size_from_fd fd] returns the size of the terminal accessible via
      the given file descriptor. *)

val set_size_from_fd : Lwt_unix.file_descr -> LTerm_geom.size -> unit Lwt.t
  (** [set_size_from_fd fd size] tries to set the size of the terminal
      accessible via the given file descriptor. *)

(** {6 Modification} *)

val set_io :
  ?incoming_fd : Lwt_unix.file_descr -> ?incoming_channel : Lwt_io.input_channel ->
  ?outgoing_fd : Lwt_unix.file_descr -> ?outgoing_channel : Lwt_io.output_channel -> t -> unit Lwt.t
  (** Modifies file descriptors/channels of a terminal. Unspecified
      arguments are kept unchanged.

      Note: before modifying a terminal you should ensure that no
      operation is pending on it. *)

(**/**)
val get_size : t -> LTerm_geom.size Lwt.t
val set_size : t -> LTerm_geom.size -> unit Lwt.t
