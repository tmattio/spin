(*
 * lTerm_widget.ml
 * ---------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

module Make (LiteralIntf: LiteralIntf.Type) = struct
  open LTerm_geom
  open LTerm_draw

  (* +-----------------------------------------------------------------+
    | The widget class                                                |
    +-----------------------------------------------------------------+ *)

  class t = LTerm_widget_base_impl.t

  (* +-----------------------------------------------------------------+
    | Labels                                                          |
    +-----------------------------------------------------------------+ *)

  let newline = Zed_char.unsafe_of_char '\n'

  let text_size str =
    let rec loop ofs rows cols max_cols =
      if ofs = Zed_string.bytes str then
        { rows; cols = max cols max_cols }
      else
        let chr, ofs = Zed_string.extract_next str ofs in
        if chr = newline then
          if ofs = Zed_string.bytes str then
            { rows; cols = max cols max_cols }
          else
            loop ofs (rows + 1) 0 (max cols max_cols)
        else
          let width= max (Zed_char.width chr) 0 in
          loop ofs rows (cols + width) max_cols
    in
    loop 0 1 0 0

  class label initial_text = object(self)
    inherit t "label"
    val mutable text = LiteralIntf.to_string_exn initial_text

    val mutable size_request = text_size (LiteralIntf.to_string_exn initial_text)
    method! size_request = size_request

    val mutable style = LTerm_style.none
    method! update_resources =
      style <- LTerm_resources.get_style self#resource_class self#resources

    method text = LiteralIntf.of_string text
    method set_text t =
      let t= LiteralIntf.to_string_exn t in
      text <- t;
      size_request <- text_size t;
      self#queue_draw

    val mutable alignment = H_align_center
    method set_alignment a = alignment <- a

    method! draw ctx _focused =
      let { rows ; _ } = LTerm_draw.size ctx in
      let row = (rows - size_request.rows) / 2 in
      LTerm_draw.fill_style ctx style;
      LTerm_draw.draw_string_aligned ctx row alignment text
  end

  (* +-----------------------------------------------------------------+
    | Boxes                                                           |
    +-----------------------------------------------------------------+ *)

  module LTerm_containers = LTerm_containers_impl.Make(LiteralIntf)
  exception Out_of_range = LTerm_containers.Out_of_range
  class type box = LTerm_containers.box
  class hbox = LTerm_containers.hbox
  class vbox = LTerm_containers.vbox
  class frame = LTerm_containers.frame
  class modal_frame = LTerm_containers.modal_frame

  (* +-----------------------------------------------------------------+
    | Spacing for layout control (aka glue)                           |
    +-----------------------------------------------------------------+ *)

  class spacing ?(rows=0) ?(cols=0) () = object
    inherit t "glue"
    val size_request = { rows; cols }
    method! size_request = size_request
  end

  (* +-----------------------------------------------------------------+
    | Lines                                                           |
    +-----------------------------------------------------------------+ *)

  class hline = object(self)
    inherit t "hline"

    val size_request = { rows = 1; cols = 0 }
    method! size_request = size_request

    val mutable style = LTerm_style.none
    val mutable connection = LTerm_draw.Light
    method! update_resources =
      let rc = self#resource_class and resources = self#resources in
      style <- LTerm_resources.get_style rc resources;
      connection <- LTerm_resources.get_connection (rc ^ ".connection") resources

    method! draw ctx _focused =
      let { rows ; _ } = LTerm_draw.size ctx in
      LTerm_draw.fill_style ctx style;
      draw_hline ctx (rows / 2) 0 (LTerm_draw.size ctx).cols connection
  end

  class vline = object(self)
    inherit t "vline"

    val size_request = { rows = 0; cols = 1 }
    method! size_request = size_request

    val mutable style = LTerm_style.none
    val mutable connection = LTerm_draw.Light
    method! update_resources =
      let rc = self#resource_class and resources = self#resources in
      style <- LTerm_resources.get_style rc resources;
      connection <- LTerm_resources.get_connection (rc ^ ".connection") resources

    method! draw ctx _focused =
      let { cols ; _ } = LTerm_draw.size ctx in
      LTerm_draw.fill_style ctx style;
      draw_vline ctx 0 (cols / 2) (LTerm_draw.size ctx).rows connection
  end

  (* +-----------------------------------------------------------------+
    | Buttons                                                         |
    +-----------------------------------------------------------------+ *)

  module LTerm_buttons = LTerm_buttons_impl.Make(LiteralIntf)
  class button = LTerm_buttons.button
  class checkbutton = LTerm_buttons.checkbutton
  class type ['a] radio = ['a] LTerm_buttons.radio
  class ['a] radiogroup = ['a] LTerm_buttons.radiogroup
  class ['a] radiobutton = ['a] LTerm_buttons.radiobutton

  (* +-----------------------------------------------------------------+
    | Scrollbars                                                      |
    +-----------------------------------------------------------------+ *)

  class adjustment = LTerm_scroll_impl.adjustment

  (** Interface between an adjustment and a scrollbar widget. *)
  class type scrollable_adjustment = object
    inherit adjustment
    method incr : int
    method decr : int
    method mouse_scroll : int -> int
    method set_scroll_bar_mode : [ `fixed of int | `dynamic of int ] -> unit
    method set_mouse_mode : [ `middle | `ratio | `auto ] -> unit
    method set_min_scroll_bar_size : int -> unit
    method set_max_scroll_bar_size : int -> unit
    method on_scrollbar_change : ?switch:LTerm_widget_callbacks.switch ->
      (unit -> unit) -> unit
  end

  class type scrollable_document = object
    method page_size : int
    method set_page_size : int -> unit
    method document_size : int
    method set_document_size : int -> unit
    method page_next : int
    method page_prev : int
    method calculate_range : int -> int -> int
  end

  class type scrollable_private = object
    method set_scroll_window_size : int -> unit
    method get_render_params : int * int * int
  end

  class type default_scroll_events = object
    method mouse_event : LTerm_event.t -> bool
    method scroll_key_event : LTerm_event.t -> bool
  end

  class scrollable = LTerm_scroll_impl.scrollable_adjustment

  class vscrollbar = LTerm_scroll_impl.vscrollbar

  class hscrollbar = LTerm_scroll_impl.hscrollbar

  class vslider = LTerm_scroll_impl.vslider

  class hslider = LTerm_scroll_impl.hslider

  (* +-----------------------------------------------------------------+
    | Running in a terminal                                           |
    +-----------------------------------------------------------------+ *)

  let run = LTerm_running_impl.run
  let run_modal = LTerm_running_impl.run_modal
  let prepare_simple_run = LTerm_running_impl.prepare_simple_run
end
