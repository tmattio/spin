open LTerm_geom
open LTerm_key

class t = LTerm_widget_base_impl.t

(* About focus; widgets may specify an optional target widget in each direction.
   The focus specification is intepreted in two ways based on can_focus.

   can_focus=true

      If the currently focussed widget has a focus specification in the required
      direction that widget is jumped to.  Otherwise a search is performed.

   can_focus=false

      Widgets with can_focus=false will never be the current focus, however,
      they can take part in search for a widget.  When we search over such
      a widget, if it has an appropriate focus specification then we jump
      there.
*)
let get_focus x dir =
  let f = function None -> `none | Some(x) -> `set_focus(x) in
  match dir with
  | `left -> f x.left
  | `right -> f x.right
  | `up -> f x.up
  | `down -> f x.down

let make_widget_matrix root dir =
  let { rows; cols } = LTerm_geom.size_of_rect root#allocation in
  let m = Array.make_matrix rows cols `none in
  let rec loop widget =
    let set rect widget =
      if widget <> `none then begin
        for r = rect.row1 to rect.row2 - 1 do
          for c = rect.col1 to rect.col2 - 1 do
            m.(r).(c) <- widget
          done
        done
      end
    in
    if widget#can_focus then begin
      set widget#allocation (`can_focus widget)
    end else begin
      set widget#allocation (get_focus widget#focus dir)
    end;
    List.iter loop widget#children
  in
  loop root;
  m

let left coord = { coord with col = pred coord.col }
let right coord = { coord with col = succ coord.col }
let up coord = { coord with row = pred coord.row }
let down coord = { coord with row = succ coord.row }

let focus_to (dir,incr_dir) f root focused coord =
  let get_coord widget =
    let rect = widget#allocation in
    { col = (rect.col1 + rect.col2) / 2;
      row = (rect.row1 + rect.row2) / 2 }
  in
  match get_focus focused#focus dir with
  | `set_focus(widget) ->
    (* If the currently focused widget has a focus specification for
       the given direction jump directly to that widget *)
    Some(widget, get_coord widget)
  | `none ->
    (* Otherwise project a line in the appropriate direction until we hit a widget. *)
    let rect = root#allocation in
    let m = make_widget_matrix root dir in
    let rec loop coord =
      if coord.row < rect.row1 || coord.row >= rect.row2 || coord.col < rect.col1 || coord.col >= rect.col2 then
        None
      else
        match m.(coord.row).(coord.col) with
        | `none ->
            loop (incr_dir coord)
        | `can_focus widget when widget = focused ->
            loop (incr_dir coord)
        | `can_focus widget ->
            let rect = widget#allocation in
            Some (widget, f rect coord)
        | `set_focus widget -> (* note; this allows widget=focused, if specified *)
            Some (widget, get_coord widget)
    in
    loop coord

let avg_col rect coord = { coord with col = (rect.col1 + rect.col2) / 2 }
let avg_row rect coord = { coord with row = (rect.row1 + rect.row2) / 2 }

let focus_left (* root focused coord *) = focus_to (`left,left) avg_col
let focus_right (* root focused coord *) = focus_to (`right,right) avg_col
let focus_up (* root focused coord *) = focus_to (`up,up) avg_row
let focus_down (* root focused coord *) = focus_to (`down,down) avg_row

class toplevel focused widget = object(self)
  inherit t "toplevel" as super
  val children = [widget]
  method! children = children
  method! draw ctx focused = widget#draw ctx focused

  val mutable coord = { row = 0; col = 0 }
    (* Coordinates of the cursor inside the screen. *)

  val mutable push_layer_handler = Lwt_react.E.never;
  val mutable pop_layer_handler = Lwt_react.E.never;

  method arm_layer_handlers (push_event : t Lwt_react.event)
                            (push_handler : t -> unit)
                            (pop_event : unit Lwt_react.event)
                            (pop_handler : unit -> unit) =
    let open Lwt_react in
    push_layer_handler <- E.map push_handler push_event;
    pop_layer_handler <- E.map pop_handler pop_event

  method! set_allocation rect =
    super#set_allocation rect;
    widget#set_allocation rect;
    let rect = !focused#allocation in
    coord <- { row = (rect.row1 + rect.row2) / 2;
               col = (rect.col1 + rect.col2) / 2 }

  method move_focus_to = function
    | Some (widget, c) ->
      coord <- c;
      focused := widget;
      self#queue_draw
    | None ->
      ()

  method private move_focus direction =
    self#move_focus_to @@ direction (self :> t) !focused coord

  method private process_arrows = function
    | LTerm_event.Key { control = false; meta = false; shift = false; code = Left } ->
        self#move_focus focus_left;
        true
    | LTerm_event.Key { control = false; meta = false; shift = false; code = Right } ->
        self#move_focus focus_right;
        true
    | LTerm_event.Key { control = false; meta = false; shift = false; code = Up } ->
        self#move_focus focus_up;
        true
    | LTerm_event.Key { control = false; meta = false; shift = false; code = Down } ->
        self#move_focus focus_down;
        true
    | _ ->
        false

  initializer
    widget#set_parent (Some (self :> t));
    self#on_event self#process_arrows

end
