open Opium_kernel

let router : Rock.Handler.t Opium_kernel.Router.t = Router.empty

let scope ?(route = "") ?(middlewares = []) router routes =
  ListLabels.fold_left
    routes
    ~init:router
    ~f:(fun router (meth, subroute, action) ->
      let filters =
        ListLabels.map ~f:(fun m -> m.Rock.Middleware.filter) middlewares
      in
      let service = Rock.Filter.apply_all filters action in
      Router.add
        router
        ~action:service
        ~meth
        ~route:(Route.of_string (route ^ subroute)))

let router =
  scope
    router
    ~route:"/users"
    [ `GET, "", Account_handler.index
    ; `GET, "/:id/settings", Account_handler.edit
    ; `GET, "/new", Account_handler.new_
    ; `GET, "/:id", Account_handler.show
    ; `POST, "", Account_handler.create
    ; `Other "PATCH", "/:id", Account_handler.update
    ; `PUT, "/:id", Account_handler.update
    ; `DELETE, "/:id", Account_handler.delete
    ]
