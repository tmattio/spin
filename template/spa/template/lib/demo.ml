let start () =
  Incr_dom.Start_app.start
    ~bind_to_element_with_id:"root"
    ~initial_model:App.Model.empty
    (module App)
