module Model = struct
  type t =
    { location : string
    ; page_home_model : Page_home.Model.t
    }

  let cutoff
      { location = location_1; page_home_model = page_home_model_1 }
      { location = location_2; page_home_model = page_home_model_2 }
    =
    String.compare location_1 location_2 = 0
    && Page_home.Model.cutoff page_home_model_1 page_home_model_2

  let update_location t location = { t with location }

  let empty =
    { location = (Router.current_location ()).hash
    ; page_home_model = Page_home.Model.empty
    }
end

module Action = struct
  type t =
    | UrlChange of Router.location
    | Page_home_action of Page_home.Action.t
  [@@deriving sexp_of]

  let apply model action _state ~schedule_action : Model.t =
    match action with
    | UrlChange location ->
      Model.update_location model location.hash
    | Page_home_action action ->
      { model with
        page_home_model =
          Page_home.Action.apply
            model.Model.page_home_model
            action
            ()
            ~schedule_action:(fun action ->
              schedule_action (Page_home_action action))
      }
end

module State = struct
  type t = { schedule : Action.t -> unit } [@@deriving fields]
end

let on_startup ~schedule_action:schedule _ =
  let state = { State.schedule } in
  let _event =
    Router.on_location_change ~f:(fun loc -> schedule (Action.UrlChange loc))
  in
  Async_kernel.return state

let on_display ~old_model:_ _ ~schedule_action:_ = ()

let view model ~inject =
  let open Incr_dom.Incr.Let_syntax in
  let%map model = model in
  match Router.route_of_location model.Model.location with
  | Some Home ->
    Page_home.view model.page_home_model ~inject:(fun action ->
        inject (Action.Page_home_action action))
  | None ->
    Page_not_found.view ()

let create model ~old_model ~inject =
  let open Incr_dom.Incr.Let_syntax in
  let%map apply_action =
    let%map model = model in
    Action.apply model
  and on_display =
    let%map old_model = old_model in
    on_display ~old_model
  and view = view model ~inject
  and model = model in
  Incr_dom.Component.create ~apply_action ~on_display model view
