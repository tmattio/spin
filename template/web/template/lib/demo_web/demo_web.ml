(** Entrypoint to Demo' web library. *)

module Handler = struct
  module Page = Page_handler
  module Account = Account_handler
end

(** [handler] is the server default handler.

    When a request is received, it is piped through the middlewares and
    eventually gets routed to the appropriate handler by the router middleware
    [Middleware.router]. In the case where the router middleware fails to match
    the request with a route, the default handler is used a fallback. In our
    case, every route that is not handled by the server will be handled by the
    frontend application. *)
let handler _req =
  Lwt.return
  @@ Opium_kernel.Response.of_html
       (Error_view.fallback ~status:`Not_found ~error:"Page not found!" ())

(** [middlewares] is the list of middlewares used by every endpoints of the
    application's API.

    Most of the time, middlewares are scoped to a set of routes. Scoped
    middlewares should be added to the router ([Middleware.router]). But in
    situation where you want to pipe every incoming requests through a
    middleware (e.g. to globally reject a User-Agent), you can add the
    middleware to this list. *)
let middlewares =
  [ (* The router of the application. It will try to match the requested URI
       with one of the defined route. If it finds a match, it will call the
       appropriate handler. If no route is found, it will call the default
       handler. *)
    Opium_kernel.Middleware.router Router.router
  ; (* Serving static files *)
    Opium_kernel.Middleware.static
      ~read:(fun fname ->
        match Asset.read fname with
        | None ->
          Lwt.return (Error `Not_found)
        | Some body ->
          Lwt_result.return @@ Opium_kernel.Body.of_string body)
      ()
  ; (* Add Content-Length header *)
    Opium_kernel.Middleware.content_length
  ; (* Logging requests *)
    Opium_kernel.Middleware.logger ()
  ]

let middlewares =
  if Demo.Config.is_prod then
    middlewares
  else
    middlewares @ [ Opium_kernel.Middleware.debugger () ]

(** [app] represents our web application as list of middleware and an handler.

    It is meant to be used from an Httpaf server. If you're using Unix as a
    backend, you can convert the app from a [Opium_kernel.Rock.App] to an
    [Opium.App] and serve it with [Opium.App.run_command] *)
let app = Opium_kernel.Rock.App.create ~middlewares ~handler
