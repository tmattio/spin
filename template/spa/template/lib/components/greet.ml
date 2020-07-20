open Incr_dom

module Model = struct
  type t = int

  let cutoff : t -> t -> bool = ( = )

  let empty = 0
end

module State = struct
  type t = unit
end

module Action = struct
  type t =
    | Increment
    | Decrement
  [@@deriving sexp_of]

  let apply model action _state ~schedule_action:_ =
    match action with Increment -> model + 1 | Decrement -> model - 1
end

let on_startup ~schedule_action:_ _ : State.t Async_kernel.Deferred.t =
  Async_kernel.return ()

let view model ~inject =
  let open Virtual_dom.Tyxml.Html in
  div
    ~a:[ a_class [ "text-center mt-12" ] ]
    [ p
        ~a:[ a_class [ "text-3xl text-gray-900 mb-4" ] ]
        [ txt "👋 Welcome Visitor! You can edit me in"
        ; code
            [ txt
                {|
  lib/components/greet.{% if syntax == 'Reason' %}re{% else %}ml{% endif %}|}
            ]
        ]
    ; p
        ~a:[ a_class [ "text-xl text-gray-900 mb-4" ] ]
        [ txt
            "Here a simple counter example that you can look at to get started:"
        ]
    ; div
        ~a:[ a_class [ "space-x-6" ] ]
        [ button
            ~a:
              [ a_button_type `Button
              ; a_onclick (fun _event -> inject Action.Decrement)
              ; a_class
                  [ "inline-flex items-center px-4 py-2 border border-gray-300 \
                     text-sm leading-5 font-medium rounded-md text-gray-700 \
                     bg-white hover:text-gray-500"
                  ]
              ]
            [ txt "-" ]
        ; span
            ~a:
              [ a_class
                  [ "inline-flex items-center px-4 py-2 border border-gray-300 \
                     text-sm leading-5 font-medium rounded-md text-gray-700 \
                     bg-white hover:text-gray-500"
                  ]
              ]
            [ txt (string_of_int model) ]
        ; button
            ~a:
              [ a_button_type `Button
              ; a_onclick (fun _event -> inject Action.Increment)
              ; a_class
                  [ "inline-flex items-center px-4 py-2 border border-gray-300 \
                     text-sm leading-5 font-medium rounded-md text-gray-700 \
                     bg-white hover:text-gray-500"
                  ]
              ]
            [ txt "+" ]
        ]
    ]
  |> Virtual_dom.Tyxml.Html.toelt

let create model ~old_model:_ ~inject =
  let%map.Incr model = model in
  let view = view model ~inject in
  Component.create model view ~apply_action:(Action.apply model)
