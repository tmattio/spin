(*
 * lTerm_widget.mli
 * ----------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

(** Widgets for creating applications *)

(** {6 Base class} *)

(** The base class. The parameter is the initial resource class. The
    resource class is the first part of all resource keys used by the
    widget.

    For examples, buttons use the resources
    ["button.focused.foreground"], ["button.unfocused.bold"], ... so
    their resource class is ["button"].
*)

class t : string -> object
  method children : t list
    (** The children of the widget. *)

  method parent : t option
    (** The parent of the widget, if any. *)

  method set_parent : t option -> unit
    (** Sets the parent of the widget. This also affect
        {!queue_draw}. *)

  method can_focus : bool
    (** Whether the widget can receive the focus or not. *)

  method focus : t option LTerm_geom.directions
    (** Specify a target widget to the left, right, up and/or down
        when changing focus. *)

  method set_focus : t option LTerm_geom.directions -> unit
    (** Sets the target widgets when changing focus. *)

  method queue_draw : unit
    (** Enqueue a redraw operation. If the widget has a parent, this
        is the same as calling the {!queue_draw} method of the parent,
        otherwise this does nothing. *)

  method set_queue_draw : (unit -> unit) -> unit
    (** [set_queue_draw f] sets the function called when the
        {!queue_draw} method is invoked, for this widget and all its
        children. *)

  method draw : LTerm_draw.context -> t -> unit
    (** [draw ctx focused] draws the widget on the given
        context. [focused] is the focused widget. *)

  method cursor_position : LTerm_geom.coord option
    (** Method invoked when the widget has the focus, it returns the
        position of the cursor inside the widget if it should be
        displayed. *)

  method allocation : LTerm_geom.rect
    (** The zone occuped by the widget. *)

  method set_allocation : LTerm_geom.rect -> unit
    (** Sets the zone occuped by the widget. *)

  method send_event : LTerm_event.t -> unit
    (** Send an event to the widget. If the widget cannot process the
        event, it is sent to the parent and so on. *)

  method on_event : ?switch : LTerm_widget_callbacks.switch -> (LTerm_event.t -> bool) -> unit
    (** [on_event ?switch f] calls [f] each time an event is
        received. If [f] returns [true], the event is not passed to
        other callbacks. *)

  method size_request : LTerm_geom.size
    (** The size wanted by the widget. *)

  method resources : LTerm_resources.t
    (** The set of resources used by the widget. *)

  method set_resources : LTerm_resources.t -> unit
    (** Sets the resources of the widget and of all its children. *)

  method resource_class : string
    (** The resource class of the widget. *)

  method set_resource_class : string -> unit
    (** Sets the resource class of the widget. This can be used to set
        an alternative style for the widget. *)

  method update_resources : unit
    (** Method invoked when the resources or the resource class of the
        widget change. The default function does nothing. *)
end

(** {6 Labels} *)

(** A widget displaying a text. *)
class label : string -> object
  inherit t

  method text : string
    (** The text of the label. *)

  method set_alignment : LTerm_geom.horz_alignment -> unit
    (** Set text alignment. *)

  method set_text : string -> unit
end

(** {6 Containers} *)

exception Out_of_range

(** Type of widgets displaying a list of widget. *)
class type box = object
  inherit t

  method add : ?position : int -> ?expand : bool -> #t -> unit
    (** [add ?position ?expand widget] adds a widget to the box. If
        [expand] is [true] (the default) then [widget] will occupy as
        much space as possible. If [position] is not specified then
        the widget is appended to the end of the widget list. It
        raises {!Out_of_range} if the given position is negative or
        exceed the number of widgets. *)

  method remove : #t -> unit
    (** [remove widget] remove a widget from the box. *)
end

(** A widget displaying a list of widgets, listed horizontally. *)
class hbox : box

(** A widget displaying a list of widgets, listed vertically. *)
class vbox : box

(** A widget displayiing another widget in a box. *)
class frame : object
  inherit t

  method set : #t -> unit
    (** Set the widget that is inside the frame. *)

  method empty : unit
    (** Remove the child of the frame. *)

  method set_label : ?alignment:LTerm_geom.horz_alignment -> string -> unit
    (** Set label rendered in the top row of the frame *)
end

(** A widget displaying a frame around child widget. Unlike {!frame}, the child
    widget is not expanded to take all available space; instead the child is
    centered and frame is drawn around it. This is a utility class for creation
    of modal dialogs and similar widgets. *)
class modal_frame : object
  inherit frame
end

(** A widget used for layout control within boxes *)
class spacing : ?rows:int -> ?cols:int -> unit -> t

(** {6 Lines} *)

(** A horizontal line. *)
class hline : t

(** A vertical line. *)
class vline : t

(** {6 Buttons} *)

(** Normal button. *)
class button : ?brackets:(string * string) -> string -> object
  inherit t

  method label : string
    (** The text displayed on the button. *)

  method label_zed : Zed_string.t
    (** The text displayed on the button. *)

  method set_label : string -> unit

  method on_click : ?switch : LTerm_widget_callbacks.switch -> (unit -> unit) -> unit
    (** [on_click ?switch f] calls [f] when the button is clicked. *)
end

(** Checkbutton. A button that can be in active or inactive state. *)
class checkbutton : string -> bool -> object
  inherit t

  method label : string
    (** The text displayed on the checkbutton. *)

  method label_zed : Zed_string.t
    (** The text displayed on the button. *)

  method state : bool
    (** The state of checkbutton; [true] means checked and [false] means unchecked. *)

  method set_label : string -> unit

  method on_click : ?switch : LTerm_widget_callbacks.switch -> (unit -> unit) -> unit
  (** [on_click ?switch f] calls [f] when the button state is changed. *)
end

class type ['a] radio = object
  method on : unit
  method off : unit
  method id : 'a
end

(** Radio group.

 Radio group governs the set of {!radio} objects. At each given moment of time only one
 of the objects in the "on" state and the rest are in the "off" state. *)
class ['a] radiogroup : object

  method on_state_change : ?switch : LTerm_widget_callbacks.switch -> ('a option -> unit) -> unit
  (** [on_state_change ?switch f] calls [f] when the state of the group is changed. *)

  method state : 'a option
  (** The state of the group. Contains [Some id] with the id of "on" object
   in the group or None if no objects were added to the group yet. *)

  method register_object : 'a radio -> unit
  (** Adds radio object to the group *)

  method switch_to : 'a -> unit
  (** [switch_to id] switches radio group to the state [Some id], calls {!radio.on}
  method of the object with the given id and {!radio.off} method of all other objects
  added to the group. *)

end

(** Radiobutton. The button which implements {!radio} object contract, so can be
 added to {!radiogroup}. *)
class ['a] radiobutton : 'a radiogroup -> string -> 'a -> object
  inherit t

  method state : bool
  (** The state of the button; [true] if button is "on" and [false] if the button
   is "off". *)

  method on : unit
  (** Switches the button state to "on". Affects only how the button is drawn,
   does not change the state of the group the button is added to.
   Use {!radiogroup.switch_to} instead. *)

  method off : unit
  (** Switches the button state to "off". Affects only how the button is drawn,
   does not change the state of the group the button is added to.
   Use {!radiogroup.switch_to} instead. *)

  method label : string
  (** The text displayed on the radiobutton. *)

  method label_zed : Zed_string.t
    (** The text displayed on the button. *)

  method set_label : string -> unit

  method id : 'a
  (** The id of the button. *)

  method on_click : ?switch:LTerm_widget_callbacks.switch -> (unit -> unit) -> unit
  (** [on_click ?switch f] calls [f] when the button is clicked. You probably want
   to use {!radiogroup.on_state_change} instead. *)

end

(** {6 Scrollbars} *)

(** Adjustable integer value from (0..range-1) *)
class adjustment : object

  method range : int
    (** range of adjustment *)

  method set_range : ?trigger_callback:bool -> int -> unit
    (** set range of adjustment. *)

  method offset : int
    (** offset from (0..range-1) *)

  method set_offset : ?trigger_callback:bool -> int -> unit
    (** Set offset clipped to range. *)

  method on_offset_change : ?switch:LTerm_widget_callbacks.switch ->
     (int -> unit) -> unit
    (** [on_offset_change ?switch f] calls f when the offset changes. *)

end

(** Interface between an adjustment and a scrollbar widget. *)
class type scrollable_adjustment = object

  inherit adjustment

  method incr : int
    (** Return offset incremented by one step

    If range > number of scroll bar steps then step>=1. *)

  method decr : int
    (** Return offset decremented by one step *)

  method mouse_scroll : int -> int
    (** [adj#mouse_scroll offset] computes the scroll bar based on a click
    [offset] units from the top/left *)

  method set_scroll_bar_mode : [ `fixed of int | `dynamic of int ] -> unit
    (** Configure how the size of the scrollbar is calculated.

     [`fixed x] sets the size to x.

     [`dynamic 0] sets the size to reflect the ratio between
     the range and scroll window size.

     [`dynamic x] (x>0) interprets [x] as the viewable size and
     sets the size of the scroll bar to reflect the amount of
     content displayed relative to range. *)

  method set_mouse_mode : [ `middle | `ratio | `auto ] -> unit
    (** Configure how a mouse coordinate is converted to a scroll bar offest.

     [`middle] sets the middle of the scrollbar to the position clicked.

     [`ratio] computes the offset relative to the scroll bar and scroll window sizes,
     with a 10% deadzone at the extremities.

     [`auto] chooses [`middle] mode if the scroll bar size is less than half the window
     size and [`ratio] otherwise. *)

  method set_min_scroll_bar_size : int -> unit
    (** Set the minimum scroll bar size (default:1) *)

  method set_max_scroll_bar_size : int -> unit
    (** Set the maximum scroll bar size (default: scroll window size *)

  method on_scrollbar_change : ?switch:LTerm_widget_callbacks.switch ->
    (unit -> unit) -> unit
    (** [on_scrollbar_change ?switch f] calls f when the scrollbar is changed and
     needs to be re-drawn. *)

end

(* Automatic configuration of the scrollbar.

  The [set_page_size] and [set_document_size] methods will configure
  the scrollbar to reflect the currently viewed area of a document.

  [calculate_range] can be overriden to configure how much extra space
  is shown at the end of a document.  By default the last line of a document
  will be shown at the bottom of the viewable area using

  [range = document_size - page_size + 1] *)
class type scrollable_document = object

  method page_size : int
    (** Viewable size *)

  method set_page_size : int -> unit
    (** Set viewable size *)

  method document_size : int
    (** Document size *)

  method set_document_size : int -> unit
    (** Set document size *)

  method page_next : int
    (** Offset of next page *)

  method page_prev : int
    (** Offset of previous page *)

  method calculate_range : int -> int -> int
    (** [calculate_range page_size document_size] returns the range
     used by the scrollbar. *)

end

(** Interface used by the scrollbar widget to configure the
  scrollbar and get parameters needed for rendering *)
class type scrollable_private = object

  method set_scroll_window_size : int -> unit
    (** The attached scroll bar needs to provide its window
    size during [set_allocation] *)

  method get_render_params : int * int * int
    (** Provide the scroll bar with rendering parameters *)

end

(** Main object implementing scroll logic for coordination
 between a scrollable wigdet and a scrollbar widget.

 [scrollable_adjustment] implements the main logic and provides a
 lowlevel interface for controlling how mouse events are translated
 to scroll offsets ([set_mouse_mode]) and the size of the scrollbar
 ([set_scroll_bar_mode]).

 [scrollable_document] provides a higher level interface for
 configuring the operation of the scrollbar where the scrollbar
 is used to reflect the area of a page within a potentially larger
 document.

 [scrollbar_private] is an internal interface between the [scrollable]
 object and a [scrollbar] used to exchange parameters needed to
 perform rendering. *)
class scrollable : object
  inherit scrollable_adjustment
  inherit scrollable_document
  inherit scrollable_private
end

(** Events exposed by scrollbar widgets.  These may be applied to
 other widgets if required. *)
class type default_scroll_events = object
  method mouse_event : LTerm_event.t -> bool
  method scroll_key_event : LTerm_event.t -> bool
end

(** Vertical scrollbar widget.

 [rc] is the resource class of the widget.  [".(un)focused"] sets the
 (un)focused style of the widget.  [".barstyle"] can be [filled] or
 [outline].  [".track"] is a bool to display a central track line.

 [default_event_handler] when true (the default) installs the
 [mouse_event] and [scroll_key_event] handlers.

 [width] (resp. [height]) defines the prefered thickness of the
 scrollbar. *)
class vscrollbar :
  ?rc:string -> ?default_event_handler:bool -> ?width:int ->
  #scrollable -> object
  inherit t
  inherit default_scroll_events
end

(** Horizontal scrollbar widget. *)
class hscrollbar :
  ?rc:string -> ?default_event_handler:bool -> ?height:int ->
  #scrollable -> object
  inherit t
  inherit default_scroll_events
end

(** Vertical slider widget. *)
class vslider : int -> object
  inherit t
  inherit adjustment
  inherit default_scroll_events
end

(** Horizontal slider widget. *)
class hslider : int -> object
  inherit t
  inherit adjustment
  inherit default_scroll_events
end

(** {6 Running in a terminal} *)

val run : LTerm.t -> ?save_state : bool -> ?load_resources : bool -> ?resources_file : string -> #t -> 'a Lwt.t -> 'a Lwt.t
  (** [run term ?save_state widget w] runs on the given terminal using
      [widget] as main widget. It returns when [w] terminates. If
      [save_state] is [true] (the default) then the state of the
      terminal is saved and restored when [w] terminates.

      If [load_resources] is [true] (the default) then
      [resources_file] (which default to ".lambda-termrc" in the home
      directory) is loaded and the result is set to [w]. *)

val run_modal : LTerm.t -> ?save_state : bool -> ?load_resources : bool -> ?resources_file : string -> t Lwt_react.event -> unit Lwt_react.event -> #t -> 'a Lwt.t -> 'a Lwt.t
  (** This function works in the same way as {!run} but also takes two
   {!Lwt_react.event} parameters. The first one should contain
   {!LTerm_widget.t} widget and makes it new topmost layer in UI. The second
   message removes the topmost level from UI. All layers are redrawn, from
   bottom to up, but only the topmost layer gets keyboard events delivered to
   it. This allows to implement things like modal dialogs.
   *)

val prepare_simple_run : unit -> (#t -> 'a Lwt.t) * (#t -> unit -> unit) * (?step:React.step -> unit -> unit) * ('a -> unit)
  (** [prepare_simple_run ()] returns a tuple [(do_run, push_layer, pop_layer,
     exit)] -- functions useful for creating simple UI.

     [do_run w] where w is a widget runs the given widget in a terminal over
     stdout, loading resources from [.lambda-termrc], saving state and
     restoring it on exit from ui.
     Example: [do_run my_frame]

     [push_layer w] where w is a widget is a callback to add w as a new modal
     layer to UI.
     Example: [button#on_click (push_layer my_modal_dialog)].

     [pop_layer] is a callback to destroy the topmost modal layer.
     Example: [cancel_button#on_click pop_layer].

     [exit] is a callback to exit the UI.
     Example: [exit_button#on_click exit]
*)

