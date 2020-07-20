let view () =
  let open Incr_dom.Tyxml.Html in
  div
    ~a:[ a_class [ "py-4 sm:py-8" ] ]
    [ div
        ~a:[ a_class [ "max-w-8xl mx-auto px-4 sm:px-6 lg:px-8" ] ]
        [ h2
            ~a:
              [ a_class
                  [ "text-2xl leading-8 font-semibold font-display \
                     text-gray-900 sm:text-3xl sm:leading-9"
                  ]
              ]
            [ txt "Not found!" ]
        ; div
            ~a:[ a_class [ "mt-0 mb-4 text-gray-600" ] ]
            [ txt "The page you are looking for cannot be found" ]
        ]
    ]
  |> Virtual_dom.Tyxml.Html.toelt
