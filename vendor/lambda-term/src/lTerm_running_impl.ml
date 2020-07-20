open Lwt
open LTerm_geom

type t = LTerm_widget_base_impl.t

class toplevel = LTerm_toplevel_impl.toplevel

(* for focus cycling *)
let rec find_focusable widget =
  if widget#can_focus then
    Some widget
  else
    find_focusable_in_list widget#children

and find_focusable_in_list = function
  | [] ->
      None
  | child :: rest ->
      match find_focusable child with
        | Some _ as some -> some
        | None -> find_focusable_in_list rest

(* Mouse support *)
let rec pick coord widget =
  if not (LTerm_geom.in_rect widget#allocation coord) then None
  else
    let f () = if widget#can_focus then Some(widget, coord)  else None in
    let w = (* search children *)
      List.fold_left
        (function None -> pick coord
                | Some(w, c) -> (fun _ -> Some(w, c)))
        None widget#children
    in
    if w = None then f() else w

(* An event for the main loop. *)
type 'a event =
  | Value of 'a
      (* A value from the waiter thread. *)
  | Event of LTerm_event.t
      (* A event from the terminal. *)

let lambda_termrc =
  Filename.concat LTerm_resources.home ".lambda-termrc"

let file_exists file =
  Lwt.catch
    (fun () ->
      Lwt_unix.access file [Unix.R_OK] >>= fun () ->
      return true)
    (function
    | Unix.Unix_error _ ->
        return false
    | exn -> Lwt.fail exn)

let apply_resources ?cache load_resources resources_file widget =
  if load_resources then
    file_exists resources_file >>= fun has_resources ->
    match has_resources with
    | true ->
        LTerm_resources.load resources_file >>= fun resources ->
        widget#set_resources resources;
        begin
          match cache with
          | None -> ()
          | Some c -> c := resources
        end;
        return ()
    | false ->
        return ()
  else
    return ()

let ref_focus widget =
  ref (match find_focusable widget with
        | Some w -> w
        | None -> widget)

let run_modal term ?save_state ?(load_resources = true) ?(resources_file = lambda_termrc) push_event pop_event widget waiter =
  let widget = (widget :> t) in
  let resources_cache = ref LTerm_resources.empty in

  apply_resources ~cache:resources_cache load_resources resources_file widget >>= fun () ->

  (* The currently focused widget. *)
  let focused = ref_focus widget in

  (* Create a toplevel widget. *)
  let toplevel = new toplevel focused widget in

  (* Drawing function for toplevels. *)
  let draw_toplevel = ref (fun () -> ()) in

  (* Size for toplevels. *)
  let size_ref = ref { row1 = 0; col1 = 0; row2 = 0; col2 = 0 } in

  let layers = ref [toplevel] in
  let focuses = ref [focused] in

  (* Layer event handlers. *)
  let push_layer w =
    let new_focus = ref_focus w in
    let new_top = new toplevel new_focus w in
    new_top#set_queue_draw !draw_toplevel;
    new_top#set_allocation !size_ref;
    focuses := new_focus :: !focuses;
    layers := new_top :: !layers;
    new_top#set_resources !resources_cache;
    new_top#queue_draw
  in
  let pop_layer () =
    match !layers with
    | [_] ->
        failwith "Trying to destroy the only existing layer."
    | _ :: tl ->
        layers := tl;
        focuses := List.tl !focuses;
        (List.hd !layers)#queue_draw
    | [] ->
        failwith "Internal error: no idea how it happened."
  in
  (* Arm layer event handlers. *)
  toplevel#arm_layer_handlers push_event push_layer pop_event pop_layer;

  let draw ui matrix =
    let ctx = LTerm_draw.context matrix (LTerm_ui.size ui) in
    LTerm_draw.clear ctx;
    (* Draw the layers starting from the bottom *)
    let layers_rev = List.rev !layers in
    let focuses_rev = List.rev !focuses in
    List.iter2 (fun top focus -> top#draw ctx !focus) layers_rev focuses_rev;
    let current_focus = List.hd !focuses in
    match !current_focus#cursor_position with
    | Some coord ->
        let rect = !current_focus#allocation in
        LTerm_ui.set_cursor_visible ui true;
        LTerm_ui.set_cursor_position ui { row = rect.row1 + coord.row;
                                          col = rect.col1 + coord.col }
    | None ->
        LTerm_ui.set_cursor_visible ui false
  in

  LTerm_ui.create term ?save_state draw >>= fun ui ->
  draw_toplevel := (fun () -> LTerm_ui.draw ui);
  toplevel#set_queue_draw !draw_toplevel;
  let size = LTerm_ui.size ui in
  size_ref := { !size_ref with row2 = size.rows; col2 = size.cols};
  toplevel#set_allocation !size_ref;

  (* Loop handling events. *)
  let waiter = waiter >|= fun x -> Value x in
  let rec loop () =
    let thread = LTerm_ui.wait ui >|= fun x -> Event x in
    choose [thread; waiter] >>= function
      | Event (LTerm_event.Resize size) ->
          size_ref := { !size_ref with row2 = size.rows; col2 = size.cols};
          List.iter (fun top -> top#set_allocation !size_ref) !layers;
          loop ()
      (* left button mouse click *)
      | Event ((LTerm_event.Mouse m) as ev) when LTerm_mouse.(m.button=Button1) -> begin
          let picked = pick LTerm_mouse.(coord m) (toplevel :> t) in
          match picked with
          | Some _ -> (* move focus and send it the event *)
            toplevel#move_focus_to picked;
            !(List.hd !focuses)#send_event ev;
            loop ()
          | None -> (* nothing got focus, so drop the event *)
            loop ()
      end
      | Event ev ->
          !(List.hd !focuses)#send_event ev;
          loop ()
      | Value value ->
          cancel thread;
          return value
  in

  Lwt.finalize loop (fun () -> LTerm_ui.quit ui)

let run term ?save_state ?load_resources ?resources_file widget waiter =
  run_modal term ?save_state ?load_resources ?resources_file Lwt_react.E.never Lwt_react.E.never widget waiter

let prepare_simple_run () =
  let waiter, wakener = wait () in
  let push_ev, push_ev_send = Lwt_react.E.create () in
  let pop_ev, pop_ev_send = Lwt_react.E.create () in
  let exit = wakeup wakener in
  let push_layer w = fun () -> push_ev_send (w :> t) in
  let pop_layer = pop_ev_send in
  let do_run w =
    Lazy.force LTerm.stdout >>= fun term ->
    run_modal term push_ev pop_ev w waiter
  in
  (do_run, push_layer, pop_layer, exit)
