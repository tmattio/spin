open Base
open Js_of_ocaml

type location =
  { href : string
  ; host : string
  ; hostname : string
  ; protocol : string
  ; origin : string option
  ; port_ : string
  ; pathname : string
  ; search : string
  ; hash : string
  }
[@@deriving sexp, compare, fields]

let location_of_js location =
  { href = location##.href |> Js.to_string
  ; host = location##.host |> Js.to_string
  ; hostname = location##.hostname |> Js.to_string
  ; protocol = location##.protocol |> Js.to_string
  ; origin = Js.Optdef.map location##.origin Js.to_string |> Js.Optdef.to_option
  ; port_ = location##.port |> Js.to_string
  ; pathname = location##.pathname |> Js.to_string
  ; search = location##.search |> Js.to_string
  ; hash = location##.hash |> Js.to_string
  }

let current_location () = location_of_js Dom_html.window##.location

(** Listen for the Dom hash change event. This binds to the event for the
    lifecycle of the application. *)
let on_location_change ~f =
  let open Js_of_ocaml in
  Js.some
    (Dom.addEventListener
       Dom_html.window
       Dom_html.Event.hashchange
       (Dom_html.handler (fun (_ev : #Dom_html.event Js.t) ->
            f (current_location ());
            Js._true))
       Js._false)

let route_of_location location =
  let location =
    match location with
    | s when String.length s > 1 && Char.equal s.[0] '#' ->
      String.sub s ~pos:1 ~len:(String.length s - 1)
    | s ->
      s
  in
  String.split location ~on:'/' |> Route.from_url
