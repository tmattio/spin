let not_found () =
  let open Tyxml.Html in
  Layout.make ~title:"Page not found · Demo" [ h1 [ txt "Not found!" ] ]

let index () =
  let open Tyxml.Html in
  Layout.make ~title:"Welcome! · Demo" [ h1 [ txt "Welcome!" ] ]
