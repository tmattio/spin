(*
 * lTerm_widget_base_impl.ml
 * ---------------------
 * Copyright : (c) 2011, Jeremie Dimino <jeremie@dimino.org>
 * Licence   : BSD3
 *
 * This file is a part of Lambda-Term.
 *)

open LTerm_widget_callbacks
open LTerm_geom

class t initial_resource_class : object
  method children : t list
  method parent : t option
  method set_parent : t option -> unit
  method can_focus : bool
  method focus : t option LTerm_geom.directions
  method set_focus : t option LTerm_geom.directions -> unit
  method queue_draw : unit
  method set_queue_draw : (unit -> unit) -> unit
  method draw : LTerm_draw.context -> t -> unit
  method cursor_position : coord option
  method allocation : rect
  method set_allocation : rect -> unit
  method send_event : LTerm_event.t -> unit
  method on_event : ?switch : switch -> (LTerm_event.t -> bool) -> unit
  method size_request : size
  method resources : LTerm_resources.t
  method set_resources : LTerm_resources.t -> unit
  method resource_class : string
  method set_resource_class : string -> unit
  method update_resources : unit
end = object(self)

  method children : t list = []

  method can_focus = false

  val mutable focus = LTerm_geom.({ left=None; right=None; up=None; down=None })
  method focus = focus
  method set_focus f =
    let check =
      function None -> ()
             | Some(x) ->
                if not ((x : t)#can_focus) then
                  failwith "set_focus: target widget must have can_focus=true"
    in
    check f.left; check f.right; check f.up; check f.down;
    focus <- f

  val mutable parent : t option = None
  method parent = parent
  method set_parent opt = parent <- opt

  val mutable queue_draw = ignore
  method queue_draw = queue_draw ()
  method set_queue_draw f =
    queue_draw <- f;
    List.iter (fun w -> w#set_queue_draw f) self#children

  method draw (_ : LTerm_draw.context) (_focused : t) = ()
  method cursor_position = None

  val mutable allocation = { row1 = 0; col1 = 0; row2 = 0; col2 = 0 }
  method allocation = allocation
  method set_allocation rect = allocation <- rect

  val event_filters = LTerm_widget_callbacks.create ()

  method send_event ev =
    if not (exec_filters event_filters ev) then
      match parent with
        | Some widget ->
            widget#send_event ev
        | None ->
            ()

  method on_event ?switch f = register switch event_filters f

  val size_request = { rows = 0; cols = 0 }
  method size_request = size_request

  val mutable resource_class = initial_resource_class
  method resource_class = resource_class
  method set_resource_class rc =
    resource_class <- rc;
    self#update_resources

  val mutable resources = LTerm_resources.empty
  method resources = resources
  method set_resources res =
    resources <- res;
    self#update_resources;
    List.iter (fun w -> w#set_resources res) self#children

  method update_resources = ()
end

