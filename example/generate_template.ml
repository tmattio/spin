let () =
  match Array.length Sys.argv with
  | argc when argc <> 2 -> 
      Printf.printf "Usage: %s TARGET_DIR\n" Sys.argv.(0)
  | _ -> 
      let target_dir = Sys.argv.(1) in
      let template_source = Spin.resolve_template_source "." in
      let template_config = Spin.get_template_config template_source in
      let template_context = Spin.build_template_context template_config in
      Spin.generate_project template_source template_config template_context target_dir
