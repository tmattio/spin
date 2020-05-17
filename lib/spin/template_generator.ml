open Dec_template

type t =
  { name : string
  ; description : string
  ; files : (string, string) Hashtbl.t
  ; context : (string, string) Hashtbl.t
  ; pre_gen_actions : Template_actions.t list
  ; post_gen_actions : Template_actions.t list
  ; message : string option
  }

let populate_files ~context ~files (dec : Generator.t) =
  let open Lwt_result.Syntax in
  let generator_files = Hashtbl.create (module String) in
  let+ _ =
    Spin_lwt.result_fold_left dec.files ~f:(fun dec_file ->
        match Hashtbl.find files dec_file.Generator.source with
        | None ->
          Lwt.return
            (Error
               (Spin_error.generator_error
                  dec.name
                  ~msg:"The generator file does not exist"))
        | Some content ->
          let+ destination =
            Template_expr.eval dec_file.destination ~context |> Lwt_result.ok
          in
          Lwt.catch
            (fun () ->
              let _ =
                Hashtbl.add generator_files ~key:destination ~data:content
              in
              Lwt.return (Ok ()))
            (function
              | Template_expr.Invalid_expr reason ->
                Error (Spin_error.generator_error dec.name ~msg:reason)
                |> Lwt.return
              | _ ->
                Error
                  (Spin_error.generator_error
                     dec.name
                     ~msg:"Failed to evaluate an expression for unknown reason")
                |> Lwt.return))
  in
  generator_files

let of_dec ?(use_defaults = false) ~context ~files (dec : Generator.t) =
  let open Lwt_result.Syntax in
  let context = Hashtbl.copy context in
  let* () =
    Template_configuration.populate_context
      ~use_defaults
      ~context
      dec.configurations
  in
  let* pre_gen_actions =
    Template_actions.of_decs_with_condition ~context dec.pre_gen_actions
  in
  let* post_gen_actions =
    Template_actions.of_decs_with_condition ~context dec.post_gen_actions
  in
  let* message =
    match dec.message with
    | Some message ->
      let+ result =
        Template_expr.to_result ~context ~f:Template_expr.eval message
      in
      Some result
    | None ->
      Lwt_result.return None
  in
  let+ files = populate_files ~context ~files dec in
  { name = dec.name
  ; description = dec.description
  ; files
  ; context
  ; pre_gen_actions
  ; post_gen_actions
  ; message
  }
