(*
 * lTerm_edit.mli
 * --------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

(** Text edition *)

(** {6 Actions} *)

type action =
  | Zed of Zed_edit.action
      (** A zed action. *)
  | Start_macro
      (** Start a new macro. *)
  | Stop_macro
      (** Ends the current macro. *)
  | Cancel_macro
      (** Cancel the current macro. *)
  | Play_macro
      (** Play the last recorded macro. *)
  | Insert_macro_counter
      (** Insert the current value of the macro counter. *)
  | Set_macro_counter
      (** Sets the value of the macro counter. *)
  | Add_macro_counter
      (** Adds a value to the macro counter. *)
  | Custom of (unit -> unit)

val bindings : action list Zed_input.Make(LTerm_key).t ref
  (** Bindings. These bindings are used by {!LTerm_read_line} and by
      edition widgets. *)

val bind : LTerm_key.t list -> action list -> unit
  (** [bind seq actions] associates [actions] to the given
      sequence. *)

val unbind : LTerm_key.t list -> unit
  (** [unbind seq] unbinds [seq]. *)

val actions : (action * string) list
  (** List of actions with their names, except {!Zed}. *)

val doc_of_action : action -> string
  (** [doc_of_action action] returns a short description of the
      action. *)

val action_of_name : string -> action
  (** [action_of_name str] converts the given action name into an
      action. Action name are the same as variants name but lowercased
      and with '_' replaced by '-'. It raises [Not_found] if the name
      does not correspond to an action. It also recognizes zed
      actions. *)

val name_of_action : action -> string
  (** [name_of_action act] returns the name of the given action. *)

(** {6 Widgets} *)

val clipboard : Zed_edit.clipboard
  (** The global clipboard. *)

val macro : action Zed_macro.t
  (** The global macro recorder. *)

(** Class of edition widgets. If no clipboard is provided, then the
    global one is used. *)
class edit :
  ?clipboard : Zed_edit.clipboard ->
  ?macro : action Zed_macro.t ->
  ?size : LTerm_geom.size -> unit -> object
  inherit LTerm_widget.t

  method engine : edit Zed_edit.t
    (** The edition engine used by this widget. *)

  method cursor : Zed_cursor.t
    (** The cursor used by this widget. *)

  method context : edit Zed_edit.context
    (** The context for editing the engine. *)

  method clipboard : Zed_edit.clipboard
    (** The clipboard used by the edition engine. *)

  method macro : action Zed_macro.t
    (** The macro recorder. *)

  method text : Zed_string.t
    (** Shorthand for [Zed_rope.to_string (Zed_edit.text
        edit#engine)]. *)

  method editable : int -> int -> bool
    (** The editable function of the engine. *)

  method match_word : Zed_rope.t -> int -> int option
    (** The match word function of the engine. *)

  method locale : string option
    (** The locale used by the engine. *)

  method set_locale : string option -> unit

  method bind : LTerm_key.t list -> action list -> unit

  method vscroll : LTerm_widget.scrollable

end
