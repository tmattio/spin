open LTerm_geom

class t = LTerm_widget_base_impl.t

let hbar = 0x2550
let vbar = 0x2551

let map_range range1 range2 offset1 =
  if range1 = 0 then 0
  else
    let map_range range1 range2 offset1 =
      max 0. (min range2 (range2 *. offset1 /. range1))
    in
    let rnd x = int_of_float (x +. 0.5) in
    rnd @@ map_range
      (float_of_int range1)
      (float_of_int range2)
      (float_of_int offset1)

class adjustment = object(self)

  (* callbacks *)
  val offset_change_callbacks = LTerm_widget_callbacks.create ()
  method on_offset_change ?switch (f : int -> unit) =
    LTerm_widget_callbacks.register switch offset_change_callbacks f

  val mutable range = 0
  val mutable offset = 0

  method range = range
  method set_range ?(trigger_callback=true) r =
    range <- max 0 r;
    self#set_offset ~trigger_callback offset (* ensure offset is clipped to the new range *)

  method offset = offset
  method set_offset ?(trigger_callback=true) o =
    let o' = max 0 (min (range-1) o) in
    if offset <> o' then begin
      offset <- o';
      if trigger_callback then
        LTerm_widget_callbacks.exec_callbacks offset_change_callbacks o'
    end

end

class scrollable_adjustment = object(self)
  inherit adjustment as adj

  val scrollbar_change_callbacks = LTerm_widget_callbacks.create ()
  method on_scrollbar_change ?switch (f : unit -> unit) =
    LTerm_widget_callbacks.register switch scrollbar_change_callbacks f

  method! set_offset ?(trigger_callback=true) o =
    adj#set_offset ~trigger_callback o;
    self#set_scroll_bar_offset (self#scroll_of_window self#offset)

  method! set_range ?(trigger_callback=true) r =
    adj#set_range ~trigger_callback r;
    self#set_scroll_bar_offset (self#scroll_of_window self#offset)

  val mutable scroll_window_size = 0
  method private scroll_window_size = scroll_window_size
  method set_scroll_window_size s = scroll_window_size <- s

  val mutable scroll_bar_mode : [ `fixed of int | `dynamic of int ] = `fixed 5
  method set_scroll_bar_mode m = scroll_bar_mode <- m

  method private scroll_bar_size_fixed size =
    let wsize = self#scroll_window_size in
    if wsize <= size then max 1 (wsize-1)
    else max 1 size

  method private scroll_bar_size_dynamic view_size =
    if range <= 1 then
      self#scroll_window_size
    else if view_size <= 0 then
      max 1 (self#scroll_window_size / max 1 range)
    else
      let range = float_of_int range in
      let scroll_size = float_of_int @@ self#scroll_window_size in
      let view_size = float_of_int view_size in
      let doc_size = view_size +. range in
      int_of_float @@ scroll_size *. view_size /. doc_size

  val mutable min_scroll_bar_size : int option = None
  method private min_scroll_bar_size =
    match min_scroll_bar_size with None -> 1 | Some(x) -> x
  method set_min_scroll_bar_size min = min_scroll_bar_size <- Some(min)

  val mutable max_scroll_bar_size : int option = None
  method private max_scroll_bar_size =
    match max_scroll_bar_size with None -> self#scroll_window_size | Some(x) -> x
  method set_max_scroll_bar_size max = max_scroll_bar_size <- Some(max)

  val mutable scroll_bar_size = 0
  method private scroll_bar_size =
    let size =
      max self#min_scroll_bar_size @@ min self#max_scroll_bar_size @@
      match scroll_bar_mode with
      | `fixed size -> self#scroll_bar_size_fixed size
      | `dynamic size -> self#scroll_bar_size_dynamic size
    in
    (if scroll_bar_size <> size then begin
      scroll_bar_size <- size;
      LTerm_widget_callbacks.exec_callbacks scrollbar_change_callbacks ()
    end);
    size

  method private scroll_bar_steps =
    self#scroll_window_size - self#scroll_bar_size + 1

  val mutable scroll_bar_offset = 0
  method private set_scroll_bar_offset o =
    let offset = max 0 (min (self#scroll_bar_steps-1) o) in
    (if scroll_bar_offset <> offset then begin
      scroll_bar_offset <- offset;
      LTerm_widget_callbacks.exec_callbacks scrollbar_change_callbacks ()
    end)

  method private window_of_scroll offset =
    map_range (self#scroll_bar_steps-1) (range-1) offset

  method private scroll_of_window offset =
    let offset = map_range (range-1) (self#scroll_bar_steps-1) offset in
    offset

  method incr =
    if range >= self#scroll_bar_steps then
      self#window_of_scroll (scroll_bar_offset+1)
    else
      (offset+1);

  method decr =
    if range >= self#scroll_bar_steps then
      self#window_of_scroll (scroll_bar_offset-1)
    else
      (offset-1);

  (* mouse click control *)

  (* scale whole scroll bar area into the number of steps.  The scroll
      bar will not necessarily end up where clicked.  Add a small dead_zone
      at far left and right *)
  method private mouse_scale_ratio scroll =
    let steps, _size = self#scroll_bar_steps, self#scroll_bar_size in
    let wsize = self#scroll_window_size in
    let dead_zone = wsize / 5 in (* ~10% at each end *)
    map_range (wsize - dead_zone - 1) (steps - 1) (scroll - dead_zone/2)

  (* place the middle of the scroll bar at the cursor.  Large scroll bars
      will reduce the clickable area by their size. *)
  method private mouse_scale_middle scroll =
    let size = self#scroll_bar_size in
    scroll - (size/2)

  method private mouse_scale_auto scroll =
    if self#scroll_bar_size > self#scroll_window_size/2 then
      self#mouse_scale_ratio scroll
    else
      self#mouse_scale_middle scroll

  val mutable mouse_mode : [ `middle | `ratio | `auto ] = `middle
  method set_mouse_mode m = mouse_mode <- m

  method private scroll_of_mouse scroll =
    match mouse_mode with
    | `middle -> self#mouse_scale_middle scroll
    | `ratio -> self#mouse_scale_ratio scroll
    | `auto -> self#mouse_scale_auto scroll

  method mouse_scroll scroll =
    self#window_of_scroll @@ self#scroll_of_mouse scroll

  val mutable page_size = -1
  val mutable document_size = -1

  method calculate_range page_size document_size = document_size-page_size+1

  method private update_page_and_document_sizes page doc =
    if page_size <> page || document_size <> doc then begin
      page_size <- page;
      document_size <- doc;
      let range = max 0 (self#calculate_range page_size document_size) in
      self#set_range range;
      self#set_mouse_mode `auto;
      self#set_scroll_bar_mode (`dynamic page_size);
    end

  method page_size = page_size
  method set_page_size s = self#update_page_and_document_sizes s document_size

  method document_size = document_size
  method set_document_size s = self#update_page_and_document_sizes page_size s

  method page_prev = self#offset - page_size
  method page_next = self#offset + page_size

  method get_render_params =
    scroll_bar_offset,
    self#scroll_bar_size,
    self#scroll_window_size

end

class virtual scrollbar
  rc default_event_handler
  (adj : #scrollable_adjustment) = object(self)
  inherit t rc

  method! can_focus = true

  (* style *)
  val mutable focused_style = LTerm_style.none
  val mutable unfocused_style = LTerm_style.none
  val mutable bar_style : [ `filled | `outline ] = `outline
  val mutable show_track = false
  method! update_resources =
    let rc = self#resource_class and resources = self#resources in
    focused_style <- LTerm_resources.get_style (rc ^ ".focused") resources;
    unfocused_style <- LTerm_resources.get_style (rc ^ ".unfocused") resources;
    bar_style <-
      (match LTerm_resources.get (rc ^ ".barstyle") resources with
      | "filled" -> `filled
      | "outline" | "" -> `outline
      | style -> Printf.ksprintf failwith "invalid scrollbar style %s" style);
    show_track <-
      (match LTerm_resources.get_bool (rc ^ ".track") resources with
      | Some(x) -> x
      | None -> false)

  (* virtual methods needed to abstract over vert/horz scrollbars *)

  method virtual private mouse_offset : LTerm_mouse.t -> rect -> int
  method virtual private scroll_incr_key : LTerm_key.t
  method virtual private scroll_decr_key : LTerm_key.t

  (* event handling *)
  method mouse_event ev =
    let open LTerm_mouse in
    let alloc = self#allocation in
    match ev with
    | LTerm_event.Mouse m when m.button=Button1 &&
                               not m.control && not m.shift && not m.meta ->
      let scroll = self#mouse_offset m alloc in
      adj#set_offset @@ adj#mouse_scroll scroll;
      true
    | _ -> false

  method scroll_key_event = function
    | LTerm_event.Key k when k = self#scroll_decr_key -> adj#set_offset adj#decr; true
    | LTerm_event.Key k when k = self#scroll_incr_key -> adj#set_offset adj#incr; true
    | _ -> false

  (* drawing *)
  method private draw_bar ctx style rect =
    let open LTerm_draw in
    let { cols; rows } = size_of_rect rect in
    if cols=1 || rows=1 || bar_style=`filled then
      let x =
        Uchar.of_int @@
          if bar_style=`filled then 0x2588
          else if cols=1 then vbar
          else hbar
      in
      for c=rect.col1 to rect.col2-1 do
        for r=rect.row1 to rect.row2-1 do
          draw_char ctx r c ~style (Zed_char.unsafe_of_uChar x)
        done
      done
    else
      draw_frame ctx rect ~style Light

  (* auto-draw *)
  initializer
    adj#on_scrollbar_change (fun () -> self#queue_draw)

  initializer
    if default_event_handler then
      self#on_event (fun ev -> self#mouse_event ev || self#scroll_key_event ev)

end

class vscrollbar
  ?(rc="scrollbar")
  ?(default_event_handler=true)
  ?(width=2)
  adj = object(self)
  inherit scrollbar rc default_event_handler adj as super

  method! size_request = { rows=0; cols=width }

  method private mouse_offset m alloc = m.LTerm_mouse.row - alloc.row1
  val scroll_incr_key = LTerm_key.{ control = false; meta = false; shift = true; code=Down}
  val scroll_decr_key = LTerm_key.{ control = false; meta = false; shift = true; code=Up}
  method private scroll_incr_key = scroll_incr_key
  method private scroll_decr_key = scroll_decr_key

  method! set_allocation r =
    super#set_allocation r;
    adj#set_scroll_window_size (r.row2 - r.row1)

  method! draw ctx focused =
    let open LTerm_draw in
    let focus = (self :> t) = focused in
    let { cols; _ } = size ctx in

    let style = if focus then focused_style else unfocused_style in
    fill_style ctx style;

    let offset, scroll_bar_size, scroll_window_size = adj#get_render_params in

    let rect =
      { row1 = offset; col1 = 0;
        row2 = offset + scroll_bar_size; col2 = cols }
    in

    (if show_track then draw_vline ctx 0 (cols/2) scroll_window_size ~style Light);
    self#draw_bar ctx style rect

end

class hscrollbar
  ?(rc="scrollbar")
  ?(default_event_handler=true)
  ?(height=2)
  adj = object(self)
  inherit scrollbar rc default_event_handler adj as super

  method! size_request = { rows=height; cols=0 }

  method private mouse_offset m alloc = m.LTerm_mouse.col - alloc.col1
  val scroll_incr_key = LTerm_key.{ control = false; meta = false; shift = true; code=Right}
  val scroll_decr_key = LTerm_key.{ control = false; meta = false; shift = true; code=Left}
  method private scroll_incr_key = scroll_incr_key
  method private scroll_decr_key = scroll_decr_key

  method! set_allocation r =
    super#set_allocation r;
    adj#set_scroll_window_size (r.col2 - r.col1)

  method! draw ctx focused =
    let open LTerm_draw in
    let focus = (self :> t) = focused in
    let { rows; _ } = size ctx in

    let style = if focus then focused_style else unfocused_style in
    fill_style ctx style;

    let offset, scroll_bar_size, scroll_window_size = adj#get_render_params in

    let rect =
      { row1 = 0; col1 = offset;
        row2 = rows; col2 = offset + scroll_bar_size }
    in

    (if show_track then draw_hline ctx (rows/2) 0 scroll_window_size ~style Light);
    self#draw_bar ctx style rect

end

class vslider rng =
  let adj = new scrollable_adjustment in
  object(self)
    inherit vscrollbar ~rc:"slider" ~default_event_handler:false ~width:1 adj
    initializer
      adj#set_mouse_mode `middle;
      adj#set_scroll_bar_mode (`fixed 1);
      adj#set_range (max 0 rng);
      self#on_event (fun ev ->
        let open LTerm_key in
        match ev with
        | LTerm_event.Key { control = false; meta = false; shift = true; code=Up} ->
        adj#set_offset (adj#offset-1);
        true
      | LTerm_event.Key { control = false; meta = false; shift = true; code=Down } ->
        adj#set_offset (adj#offset+1);
        true
      | _ -> self#mouse_event ev)
    method! size_request = { rows=rng; cols=1 }
    method offset = adj#offset
    method set_offset = adj#set_offset
    method range = adj#range
    method set_range = adj#set_range
    method on_offset_change = adj#on_offset_change
  end

class hslider rng =
  let adj = new scrollable_adjustment in
  object(self)
    inherit hscrollbar ~rc:"slider" ~default_event_handler:false ~height:1 adj
    initializer
      adj#set_mouse_mode `middle;
      adj#set_scroll_bar_mode (`fixed 1);
      adj#set_range (max 0 rng);
      self#on_event (fun ev ->
        let open LTerm_key in
        match ev with
        | LTerm_event.Key { control = false; meta = false; shift = true; code=Left } ->
        adj#set_offset (adj#offset-1);
        true
      | LTerm_event.Key { control = false; meta = false; shift = true; code=Right } ->
        adj#set_offset (adj#offset+1);
        true
      | _ -> self#mouse_event ev)
    method! size_request = { rows=1; cols=rng }
    method offset = adj#offset
    method set_offset = adj#set_offset
    method range = adj#range
    method set_range = adj#set_range
    method on_offset_change = adj#on_offset_change
  end
