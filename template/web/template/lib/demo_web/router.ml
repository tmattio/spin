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
    [ `GET, "", Account_handler.index_user
    ; `GET, "/:id/settings", Account_handler.edit_user
    ; `GET, "/new", Account_handler.new_user
    ; `GET, "/:id", Account_handler.show_user
    ; `POST, "", Account_handler.create_user
    ; `Other "PATCH", "/:id", Account_handler.update_user
    ; `PUT, "/:id", Account_handler.update_user
    ; `DELETE, "/:id", Account_handler.delete_user
    ]

let router = scope router ~route:"/" [ `GET, "", Page_handler.index ]
