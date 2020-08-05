open Base
open Js_of_ocaml

type url =
  { path : string list
  ; hash : string
  ; search : string
  }
[@@deriving sexp, compare, show, fields]

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

let path_of_location location_opt =
  match location_opt with
  | None ->
    []
  | Some location ->
    (match location.pathname with
    | "" | "/" ->
      []
    | raw ->
      let raw = String.sub raw ~pos:1 ~len:(String.length raw - 1) in
      let raw =
        match raw.[String.length raw - 1] with
        | '/' ->
          String.sub raw ~pos:0 ~len:(String.length raw - 1)
        | _ ->
          raw
      in
      String.split raw ~on:'/')

let hash_of_location location_opt =
  match location_opt with
  | None ->
    ""
  | Some location ->
    (match location.hash with
    | "" | "#" ->
      ""
    | raw ->
      String.sub raw ~pos:1 ~len:(String.length raw - 1))

let search_of_location location_opt =
  match location_opt with
  | None ->
    ""
  | Some location ->
    (match location.search with
    | "" | "?" ->
      ""
    | raw ->
      String.sub raw ~pos:1 ~len:(String.length raw - 1))

let current_url () =
  let js_location_opt =
    Js.some Dom_html.window##.location |> Js.Opt.to_option
  in
  let location_opt =
    Option.map js_location_opt ~f:(fun js_location ->
        { href = js_location##.href |> Js.to_string
        ; host = js_location##.host |> Js.to_string
        ; hostname = js_location##.hostname |> Js.to_string
        ; protocol = js_location##.protocol |> Js.to_string
        ; origin =
            Js.Optdef.map js_location##.origin Js.to_string
            |> Js.Optdef.to_option
        ; port_ = js_location##.port |> Js.to_string
        ; pathname = js_location##.pathname |> Js.to_string
        ; search = js_location##.search |> Js.to_string
        ; hash = js_location##.hash |> Js.to_string
        })
  in
  let path = path_of_location location_opt in
  let hash = hash_of_location location_opt in
  let search = search_of_location location_opt in
  { path; hash; search }

(** Listen for the Dom hash change event. This binds to the event for the
    lifecycle of the application. *)
let on_url_change ~f =
  let open Js_of_ocaml in
  Js.some
    (Dom.addEventListener
       Dom_html.window
       Dom_html.Event.popstate
       (Dom_html.handler (fun (_ev : #Dom_html.event Js.t) ->
            f (current_url ());
            Js._true))
       Js._false)

let route_of_url url = Route.from_url url.path

let push url =
  let url' = Js.string url in
  Dom_html.window##.history##pushState Js.null (Js.string "") (Js.some url');
  let event = Dom.createCustomEvent (Dom.Event.make "popstate") in
  Dom_html.window##dispatchEvent (event :> Dom_html.event Js.t)

let replace url =
  let url' = Js.string url in
  Dom_html.window##.history##replaceState Js.null url' Js.null;
  let event = Dom.createCustomEvent (Dom.Event.make "popstate") in
  Dom_html.window##dispatchEvent (event :> Dom_html.event Js.t)

let link ~route content =
  let open Incr_dom.Tyxml.Html in
  let location = Route.to_string route in
  a
    ~a:
      [ a_onclick (fun event ->
            Dom.preventDefault event;
            let (_ : bool Js.t) = push location in
            Ui_event.Ignore)
      ; a_href location
      ]
    content
