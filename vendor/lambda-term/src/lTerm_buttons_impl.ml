(*
 * lTerm_buttons_impl.ml
 * ---------------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

module Make (LiteralIntf: LiteralIntf.Type) = struct
  open LTerm_geom
  open LTerm_key
  open LTerm_mouse
  open LTerm_widget_callbacks

  let section = Lwt_log.Section.make "lambda-term(buttons_impl)"

  class t = LTerm_widget_base_impl.t

  let space = Char(Uchar.of_char ' ')

  class button ?brackets initial_label =
    let (bl, br)=
      match brackets with
      | Some (bl, br)-> LiteralIntf.to_string_exn bl, LiteralIntf.to_string_exn br
      | None-> Zed_string.unsafe_of_utf8 "< ",Zed_string.unsafe_of_utf8 " >"
    in
    let brackets_size = LTerm_text.aval_width (Zed_string.width bl)
      + LTerm_text.aval_width (Zed_string.width br)
    in

    object(self)
    inherit t "button"

    method! can_focus = true

    val click_callbacks = LTerm_widget_callbacks.create ()

    method on_click ?switch f =
      register switch click_callbacks f

    val mutable size_request = { rows = 1; cols = brackets_size + (LTerm_text.aval_width (Zed_string.width (LiteralIntf.to_string_exn initial_label))) }
    method! size_request = size_request

    val mutable label = LiteralIntf.to_string_exn initial_label

    method label = LiteralIntf.of_string label

    method label_zed = label

    method set_label text =
      let text= LiteralIntf.to_string_exn text in
      label <- text;
      size_request <- { rows = 1; cols = brackets_size + (LTerm_text.aval_width (Zed_string.width text)) };
      self#queue_draw

    initializer
      self#on_event
        (function
          | LTerm_event.Key { control = false; meta = false; shift = false; code = Enter } ->
              exec_callbacks click_callbacks ();
              true
          | LTerm_event.Mouse m when m.button = Button1 ->
              exec_callbacks click_callbacks ();
              true
          | _ ->
              false)

    val mutable focused_style = LTerm_style.none
    val mutable unfocused_style = LTerm_style.none
    method! update_resources =
      let rc = self#resource_class and resources = self#resources in
      focused_style <- LTerm_resources.get_style (rc ^ ".focused") resources;
      unfocused_style <- LTerm_resources.get_style (rc ^ ".unfocused") resources

    method private apply_style ctx focused =
      let style =
        if focused = (self :> t)
        then focused_style
        else unfocused_style
      in
      LTerm_draw.fill_style ctx style

    method! draw ctx focused =
      let { rows; cols } = LTerm_draw.size ctx in
      let width = LTerm_text.aval_width (Zed_string.width label) in
      self#apply_style ctx focused;
      LTerm_draw.draw_string ctx (rows / 2) ((cols - width - brackets_size) / 2)
        (Zed_string.append (Zed_string.append bl label) br)
  end

  class checkbutton initial_label initial_state = object(self)
    inherit button initial_label

    val mutable state = initial_state

    initializer
      self#on_event (fun ev ->
        let update () =
          state <- not state;
          (* checkbutton changes the state when clicked, so has to be redrawn *)
          self#queue_draw;
          exec_callbacks click_callbacks ();
          true
        in
        match ev with
          | LTerm_event.Key { control = false; meta = false; shift = false; code }
            when (code = Enter || code = space) -> update ()
          | LTerm_event.Mouse m
            when m.button = Button1 -> update ()
          | _ ->
              false);
      self#set_resource_class "checkbutton"

    method state = state

    method! draw ctx focused =
      let { rows; _ } = LTerm_draw.size ctx in
      let checked = Zed_string.unsafe_of_utf8 (if state then "[x] " else "[ ] ") in
      self#apply_style ctx focused;
      LTerm_draw.draw_string ctx (rows / 2) 0 (Zed_string.append checked label);

  end

  class type ['a] radio = object
    method on : unit
    method off : unit
    method id : 'a
  end

  class ['a] radiogroup  = object

    val state_change_callbacks = LTerm_widget_callbacks.create ()

    method on_state_change ?switch f =
      register switch state_change_callbacks f

    val mutable state = None
    val mutable buttons = []

    method state = state

    method register_object (button : 'a radio) =
      (* Switch the first button added to group to 'on' state *)
      if buttons = [] then button#on else ();
      buttons <- button :: buttons;
      ()

    method switch_to some_id =
      let switch_button button =
        if button#id = some_id
        then button#on
        else button#off
      in
      List.iter switch_button buttons;
      state <- Some some_id;
      exec_callbacks state_change_callbacks state

  end

  class ['a] radiobutton (group : 'a radiogroup) initial_label (id : 'a) = object(self)
    inherit button initial_label

    val mutable state = false

    initializer
      self#on_event
      (fun ev ->
        let update () =
          if state
          (* no need to do anything if the button is on already *)
          then ()
          else group#switch_to id;
          (* event is consumed in any case *)
          exec_callbacks click_callbacks ();
          true
        in
        match ev with
        | LTerm_event.Key { control = false; meta = false; shift = false; code }
          when (code = Enter || code = space) -> update ()
        | LTerm_event.Mouse m when m.button = Button1 -> update ()
        | _ -> false);
      self#set_resource_class "radiobutton";
      group#register_object (self :> 'a radio)

    method! draw ctx focused =
      let { rows; _ } = LTerm_draw.size ctx in
      let checked = Zed_string.unsafe_of_utf8 (if state then "(o) " else "( ) ") in
      self#apply_style ctx focused;
      LTerm_draw.draw_string ctx (rows / 2) 0 (Zed_string.append checked self#label_zed);

    method state = state

    method on =
      state <- true;
      self#queue_draw

    method off =
      state <- false;
      self#queue_draw

    method id = id

  end
end

