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
  let open Result.Syntax in
  let (generator_files : (string, string) Hashtbl.t) = Hashtbl.create 256 in
  let+ (_ : unit) =
    Result.List.fold_left
      (fun _ dec_file ->
        match Hashtbl.find_opt files dec_file.Generator.source with
        | None ->
          Error
            (Spin_error.generator_error
               dec.name
               ~msg:"The generator file does not exist")
        | Some content ->
          let destination = Template_expr.eval dec_file.destination ~context in
          (try Ok (Hashtbl.add generator_files destination content) with
          | Template_expr.Invalid_expr reason ->
            Error (Spin_error.generator_error dec.name ~msg:reason)
          | _ ->
            Error
              (Spin_error.generator_error
                 dec.name
                 ~msg:"Failed to evaluate an expression for unknown reason")))
      ()
      dec.files
  in
  generator_files

let of_dec ?(use_defaults = false) ~context ~files (dec : Generator.t) =
  let open Result.Syntax in
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
        Template_expr.to_result ~context Template_expr.eval message
      in
      Some result
    | None ->
      Result.ok None
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
