(** Entrypoint to Demo' web library. *)

module Common = Common

module Middleware = struct
  module Content_length = Content_length_middleware

  let static =
    Opium_kernel.Middleware.static
      ~read:(fun fname ->
        match Asset.read fname with
        | None ->
          Lwt.return_none
        | Some body ->
          Lwt.return @@ Some (Opium_kernel.Rock.Body.of_string body))
      ()

  let logger = Opium_kernel.Middleware.logger

  let debugger = Opium_kernel.Middleware.debugger ()

  let content_length = Content_length_middleware.m
end

module Handler = struct
  module Page = Page_handler
  module User = User_handler
end

(** [handler] is the server default handler.

    When a request is received, it is piped through the middlewares and
    eventually gets routed to the appropriate handler by the router middleware
    [Router.m]. In the case where the router middleware fails to match the
    request with a route, the default handler is used a fallback. In our case,
    every route that is not handled by the server will be handled by the
    frontend application. *)
let handler _req =
  Lwt.return
  @@ Helper.response_of_html
       (Error_view.fallback ~status:`Not_found ~error:"Page not found!")

(** [middlewares] is the list of middlewares used by every endpoints of the
    application's API.

    Most of the time, middlewares are scoped to a set of routes. Scoped
    middlewares should be added to the router ([Router.m]). But in situation
    where you want to pipe every incoming requests through a middleware (e.g. to
    globally reject a User-Agent), you can add the middleware to this list. *)
let middlewares =
  [ (* The router of the application. It will try to match the requested URI
       with one of the defined route. If it finds a match, it will call the
       appropriate handler. If no route is found, it will call the default
       handler. *)
    Opium_kernel.Router.m Router.router
  ; (* Serving static files *)
    Middleware.static
  ; (* Add Content-Length header *)
    Middleware.content_length
  ; (* Logging requests *)
    Middleware.logger
  ]

let middlewares =
  if Demo.Config.is_prod then
    middlewares
  else
    middlewares @ [ Middleware.debugger ]

(** [app] represents our web application as list of middleware and an handler.

    It is meant to be used from an Httpaf server. If you're using Unix as a
    backend, you can convert the app from a [Opium_kernel.Rock.App] to an
    [Opium.App] and serve it with [Opium.App.run_command] *)
let app = Opium_kernel.Rock.App.create ~middlewares ~handler
