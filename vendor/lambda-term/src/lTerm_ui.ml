(*
 * lTerm_ui.ml
 * -----------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

open LTerm_geom

let return, (>>=) = Lwt.return, Lwt.(>>=)

(* +-----------------------------------------------------------------+
   | The UI type                                                     |
   +-----------------------------------------------------------------+ *)

(* State of an UI. *)
type state =
  | Init
      (* The UI has not yet been drawn. *)
  | Loop
      (* The UI is running. *)
  | Stop
      (* The UI has been stopped. *)

type t = {
  term : LTerm.t;
  (* The terminal used for the UI. *)

  draw : t -> LTerm_draw.matrix -> unit;
  (* The draw function. *)

  mode : LTerm.mode;
  (* The previous mode of the terminal. *)

  mutable state : state;
  (* State of the UI. *)

  restore_state : bool;
  (* Whether to restore the state of the terminal when quiting. *)

  mutable size : LTerm_geom.size;
  (* The current size of the UI. *)

  mutable matrix_a : LTerm_draw.matrix;
  mutable matrix_b : LTerm_draw.matrix;
  (* The two matrices used for the rendering. *)

  mutable cursor_visible : bool;
  (* The cursor visible state. *)

  mutable cursor_position : LTerm_geom.coord;
  (* The cursor position. *)

  mutable draw_queued : bool;
  (* Is a draw operation queued ? *)

  mutable drawer : unit Lwt.t;
  (* The thread drawing the terminal. *)

  mutable drawing : bool;
  (* Are we drawing ? *)

  draw_error_push : exn option -> unit;
  draw_error_stream : exn Lwt_stream.t;
  (* Stream used to send drawing error to [loop]. *)
}

let check ui =
  if ui.state = Stop then failwith "The has been quited"

(* +-----------------------------------------------------------------+
   | Creation/quiting                                                |
   +-----------------------------------------------------------------+ *)

let create term ?(save_state = true) draw =
  LTerm.enter_raw_mode term >>= fun mode ->
  (if save_state then LTerm.save_state term else return ()) >>= fun () ->
  let stream, push = Lwt_stream.create () in
  return {
    term = term;
    draw = draw;
    mode = mode;
    state = Init;
    restore_state = save_state;
    size = LTerm.size term;
    matrix_a = [||];
    matrix_b = [||];
    cursor_visible = false;
    cursor_position = { row = 0; col = 0 };
    draw_queued = false;
    drawer = return ();
    drawing = false;
    draw_error_push = push;
    draw_error_stream = stream;
  }

let quit ui =
  check ui;
  ui.state <- Stop;
  ui.drawer >>= fun () ->
  LTerm.leave_raw_mode ui.term ui.mode >>= fun () ->
  if ui.restore_state then
    LTerm.show_cursor ui.term >>= fun () ->
    LTerm.load_state ui.term
  else
    return ()

(* +-----------------------------------------------------------------+
   | Drawing                                                         |
   +-----------------------------------------------------------------+ *)

let immediate_draw ui = fun () ->
  Lwt.catch (fun () ->
    (* Wait a bit in order not to redraw too often. *)
    Lwt.pause () >>= fun () ->
    ui.draw_queued <- false;
    if ui.state = Stop then
      return ()
    else begin
      (* Allocate the first matrix if needed. *)
      if ui.matrix_a = [||] then ui.matrix_a <- LTerm_draw.make_matrix ui.size;

      (* Draw the screen *)
      ui.drawing <- true;
      (try ui.draw ui ui.matrix_a with exn -> ui.drawing <- false; raise exn);
      ui.drawing <- false;

      (* Rendering. *)
      LTerm.hide_cursor ui.term >>= fun () ->
      LTerm.render_update ui.term ui.matrix_b ui.matrix_a >>= fun () ->
      begin
        if ui.cursor_visible then
          LTerm.goto ui.term ui.cursor_position >>= fun () ->
          LTerm.show_cursor ui.term
        else
          return ()
      end >>= fun () ->
      LTerm.flush ui.term >>= fun () ->

      (* Swap the two matrices. *)
      let a = ui.matrix_a and b = ui.matrix_b in
      ui.matrix_a <- b;
      ui.matrix_b <- a;

      return ()
    end)
    (fun exn ->
    ui.draw_error_push (Some exn);
    return ())

let draw ui =
  check ui;
  ui.state <- Loop;
  (* If a draw operation is already queued, do nothing. *)
  if not ui.draw_queued then
    (* Wait for draw operation to finish before starting new one *)
    ui.drawer <- ui.drawer >>= immediate_draw ui

(* +-----------------------------------------------------------------+
   | Accessors                                                       |
   +-----------------------------------------------------------------+ *)

let size ui =
  check ui;
  ui.size

let cursor_visible ui =
  check ui;
  ui.cursor_visible

let set_cursor_visible ui state =
  check ui;
  if state <> ui.cursor_visible then begin
    ui.cursor_visible <- state;
    if ui.state = Loop && not ui.drawing then draw ui
  end

let cursor_position ui =
  check ui;
  ui.cursor_position

let set_cursor_position ui coord =
  check ui;
  if coord <> ui.cursor_position then begin
    ui.cursor_position <- coord;
    if ui.state = Loop && not ui.drawing then draw ui
  end

(* +-----------------------------------------------------------------+
   | Loop                                                            |
   +-----------------------------------------------------------------+ *)

let wait ui =
  check ui;
  if ui.state = Init then draw ui;
  Lwt.pick [LTerm.read_event ui.term;
            Lwt_stream.next ui.draw_error_stream >>= Lwt.fail] >>= fun ev ->
  match ev with
    | LTerm_event.Resize size ->
        ui.size <- size;
        (* New size, discard current matrices. *)
        ui.matrix_a <- [||];
        ui.matrix_b <- [||];
        draw ui;
        return ev
    | _ ->
        return ev
