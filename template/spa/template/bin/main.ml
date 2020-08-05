let () =
  Incr_dom.Start_app.start
    ~bind_to_element_with_id:"root"
    ~initial_model:(Demo.App.Model.empty ())
    (module Demo.App)
