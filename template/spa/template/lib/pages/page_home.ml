open Incr_dom

module Model = struct
  type t = { greet_model : Greet.Model.t }

  let cutoff { greet_model = greet_model_1 } { greet_model = greet_model_2 } =
    Greet.Model.cutoff greet_model_1 greet_model_2

  let empty = { greet_model = Greet.Model.empty }
end

module State = struct
  type t = unit
end

module Action = struct
  type t = Greet_action of Greet.Action.t [@@deriving sexp_of]

  let apply model action _state ~schedule_action =
    match action with
    | Greet_action action ->
      Model.
        { greet_model =
            Greet.Action.apply
              model.greet_model
              action
              ()
              ~schedule_action:(fun action ->
                schedule_action (Greet_action action))
        }
end

let on_startup ~schedule_action:_ _ = Async_kernel.return ()

let view model ~inject =
  let open Vdom.Node in
  div
    []
    [ Greet.view model.Model.greet_model ~inject:(fun action ->
          inject (Action.Greet_action action))
    ]

let create model ~old_model:_ ~inject =
  let%map.Incr model = model in
  let view = view model ~inject in
  Component.create model view ~apply_action:(Action.apply model)
