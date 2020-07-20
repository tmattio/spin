let page_header ~title:title_ ?subtitle () =
  let open Tyxml.Html in
  header
    ~a:[ a_class [ "bg-white shadow-sm" ] ]
    [ div
        ~a:[ a_class [ "max-w-7xl mx-auto py-4 px-4 sm:px-6 lg:px-8" ] ]
        ([ h1
             ~a:[ a_class [ "text-lg leading-6 font-semibold text-gray-900" ] ]
             [ txt title_ ]
         ]
        @
        match subtitle with
        | Some subtitle ->
          [ p
              ~a:
                [ a_class [ "mt-1 max-w-2xl text-sm leading-5 text-gray-500" ] ]
              [ txt subtitle ]
          ]
        | None ->
          [])
    ]

let page_title ~title:title_ ?subtitle () =
  let open Tyxml.Html in
  header
    ~a:[ a_class [ "pt-10 pb-6 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8" ] ]
    ([ h1
         ~a:[ a_class [ "text-3xl font-bold leading-tight text-gray-900" ] ]
         [ txt title_ ]
     ]
    @
    match subtitle with
    | Some subtitle ->
      [ p
          ~a:[ a_class [ "mt-1 max-w-2xl text-sm leading-5 text-gray-500" ] ]
          [ txt subtitle ]
      ]
    | None ->
      [])

let content children =
  let open Tyxml.Html in
  main
    [ div
        ~a:[ a_class [ "max-w-7xl mx-auto py-6 sm:px-6 lg:px-8" ] ]
        [ div ~a:[ a_class [ "px-4 py-4 sm:px-0" ] ] children ]
    ]

let make ~title:title_ children =
  let open Tyxml.Html in
  html
    ~a:[ a_lang "en" ]
    (head
       (title (txt title_))
       [ meta ~a:[ a_charset "utf-8" ] ()
       ; meta
           ~a:
             [ a_name "viewport"
             ; a_content "width=device-width, initial-scale=1"
             ]
           ()
       ; meta ~a:[ a_name "theme-color"; a_content "#000000" ] ()
       ; meta
           ~a:[ a_name "description"; a_content "{{ project_description }}" ]
           ()
       ; link ~rel:[ `Icon ] ~href:"/favicon.ico" ()
       ; link ~rel:[ `Stylesheet ] ~href:"https://rsms.me/inter/inter.css" ()
       ; link ~rel:[ `Stylesheet ] ~href:"/main.css" ()
       ; script
           ~a:
             [ a_src
                 "https://cdn.jsdelivr.net/gh/alpinejs/alpine@v2.4.1/dist/alpine.min.js"
             ; a_defer ()
             ]
           (txt "")
       ])
    (body ~a:[ a_class [ "antialiased" ] ] children)
