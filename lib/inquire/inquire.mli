(** Inquire is a high-level library to create interactive command line
    interfaces. *)

exception Interrupted_by_user

module Style : sig
  (** Module to customize Inquire prompts. *)

  (** Available colors. *)
  type color =
    | Black
    | Red
    | Green
    | Yellow
    | Blue
    | Magenta
    | Cyan
    | White
    | Bright_black
    | Bright_red
    | Bright_green
    | Bright_yellow
    | Bright_blue
    | Bright_magenta
    | Bright_cyan
    | Bright_white
    | Default

  (** Various styles for the text. [Blink] and [Hidden] may not work on every
      terminal. *)
  type style =
    | Reset
    | Bold
    | Underlined
    | Blink
    | Inverse
    | Hidden
    | Foreground of color
    | Background of color

  val black : style
  (** Shortcut for [Foreground Black] *)

  val red : style
  (** Shortcut for [Foreground Red] *)

  val green : style
  (** Shortcut for [Foreground Green] *)

  val yellow : style
  (** Shortcut for [Foreground Yellow] *)

  val blue : style
  (** Shortcut for [Foreground Blue] *)

  val magenta : style
  (** Shortcut for [Foreground Magenta] *)

  val cyan : style
  (** Shortcut for [Foreground Cyan] *)

  val white : style
  (** Shortcut for [Foreground White] *)

  val bg_black : style
  (** Shortcut for [Background Black] *)

  val bg_red : style
  (** Shortcut for [Background Red] *)

  val bg_green : style
  (** Shortcut for [Background Green] *)

  val bg_yellow : style
  (** Shortcut for [Background Yellow] *)

  val bg_blue : style
  (** Shortcut for [Background Blue] *)

  val bg_magenta : style
  (** Shortcut for [Background Magenta] *)

  val bg_cyan : style
  (** Shortcut for [Background Cyan] *)

  val bg_white : style
  (** Shortcut for [Background White] *)

  val bg_default : style
  (** Shortcut for [Background Default] *)

  val bold : style
  (** Shortcut for [Bold] *)

  val underlined : style
  (** Shortcut for [Underlined] *)

  val blink : style
  (** Shortcut for [Blink] *)

  val inverse : style
  (** Shortcut for [Inverse] *)

  val hidden : style
  (** Shortcut for [Hidden] *)

  type t

  val default : t
  (** The default style used by Inquire prompts if none is provided. *)

  val make
    :  ?qmark_icon:string
    -> ?qmark_format:Ansi.style list
    -> ?message_format:Ansi.style list
    -> ?error_icon:string
    -> ?error_format:Ansi.style list
    -> ?default_format:Ansi.style list
    -> ?option_icon_marked:string
    -> ?option_icon_unmarked:string
    -> ?pointer_icon:string
    -> unit
    -> t
  (** Create a custom style.

      - [qmark_icon] is the icon used for the question mark that prefixes the
        prompt.
      - [qmark_format] is the format of the question mark.
      - [message_format] is the format of the prompt message.
      - [error_icon] is the icon used for error messages.
      - [error_format] is the format used for the error messages.
      - [default_format] is the format used for the default tooltip of the
        prompt, if present.
      - [option_icon_marked] is the icon used to mark selected options in
        multi-selection prompts.
      - [option_icon_unmarked] is the icon used to mark unselected options in
        multi-selection prompts.
      - [pointer_icon] is the icon used to mark the selected option in
        single-selection prompts. *)
end

val confirm
  :  ?default:bool
  -> ?auto_enter:bool
  -> ?style:Style.t
  -> string
  -> bool
(** Prompt the user to answer the given message with "y" or "n".

    {4 Examples}

    {[
      Inquire.confirm "Are you sure?" ~default:true |> fun choice ->
      if choice then print_endline "Yes!" else print_endline "No!"
    ]} *)

val password
  :  ?validate:(string -> (string, string) result)
  -> ?default:string
  -> ?style:Style.t
  -> string
  -> string
(** Prompt the user to enter a password that will be hidden.

    The password can take any value, except the empty string.

    On Unix, this works by setting the echo mode of the terminal to off.

    On Windows, we print "\x1b[8m" before prompting the password and "\x1b[0m"
    after.

    {4 Examples}

    {[ Inquire.password "Enter your password:" |> fun password -> print_endline
    "Your new password is: %S" password ]} *)

val input
  :  ?validate:(string -> (string, string) result)
  -> ?default:string
  -> ?style:Style.t
  -> string
  -> string
(** Prompt the user to input a string.

    The string can take any value, except the empty string.

    {4 Examples}

    {[
      Inquire.input "Enter a value:" |> fun value ->
      print_endline "You entered: %S" value
    ]} *)

val raw_select
  :  ?default:int
  -> ?style:Style.t
  -> options:string list
  -> string
  -> string
(** Prompt the user to chose a value from the given options. The options will be
    listed with an index prefixed and the users will have to enter the index of
    their choice.

    Note that [raw_select] does not support more than 9 options. If you need
    more options, please use [select] instead.

    {4 Examples}

    {[
      let movies =
        [ "Star Wars: The Rise of Skywalker"
        ; "Solo: A Star Wars Story"
        ; "Star Wars: The Last Jedi"
        ; "Rogue One: A Star Wars Story"
        ; "Star Wars: The Force Awakens"
        ]
      in
      Inquire.raw_select "What's your favorite movie?" ~options:movies
      |> fun movie -> print_endline "Indeed, %S is a great movie!" movie
    ]} *)

val select
  :  ?default:int
  -> ?style:Style.t
  -> options:string list
  -> string
  -> string
(** Prompt the user to chose a value from the given options. The prompt is
    interactive and users can select their choice with directional keys.

    {4 Examples}

    {[
      let movies =
        [ "Star Wars: The Rise of Skywalker"
        ; "Solo: A Star Wars Story"
        ; "Star Wars: The Last Jedi"
        ; "Rogue One: A Star Wars Story"
        ; "Star Wars: The Force Awakens"
        ]
      in
      Inquire.select "What's your favorite movie?" ~options:movies
      |> fun movie -> print_endline "Indeed, %S is a great movie!" movie
    ]} *)

val set_exit_on_user_interrupt : bool -> unit
(** Configure the behavior on user interruptions during a prompt.

    If [exit_on_user_interrupt] is [true], the program will exit with status
    code [130]. If it is [false], an [Interrupted_by_user] exception is raised.

    The default behavior is to exit on user interruptions. *)
