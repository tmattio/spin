type t =
  [ `error of string
  | `success of string
  | `warning of string
  | `info of string
  ]

let bg_of_t = function
  | `error _ ->
    "bg-red-50"
  | `success _ ->
    "bg-green-50"
  | `warning _ ->
    "bg-yellow-50"
  | `info _ ->
    "bg-blue-50"

let text_of_t = function
  | `error _ ->
    "text-red-700"
  | `success _ ->
    "text-green-700"
  | `warning _ ->
    "text-yellow-700"
  | `info _ ->
    "text-blue-700"

let message_of_t = function `error s | `success s | `warning s | `info s -> s

let make t =
  let open Tyxml.Html in
  let bg_class = [ "rounded-md"; "p-4"; bg_of_t t ] in
  let text_class = [ "text-sm"; "leading-5"; text_of_t t ] in
  let message = message_of_t t in
  div
    ~a:[ a_class bg_class ]
    [ div
        ~a:[ a_class [ "flex" ] ]
        [ div ~a:[ a_class text_class ] [ txt message ] ]
    ]
