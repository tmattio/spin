let () =
  Incr_dom.Start_app.start
    ~bind_to_element_with_id:"root"
    ~initial_model:({{ project_snake | capitalize }}.App.Model.empty ())
    (module {{ project_snake | capitalize }}.App)
