type template_source =
  | Local of string

type template_config = Template_config.t

type template_context = (string * string) list

exception Template_config_error of string
exception Context_build_error of string
exception Project_generation_error of string
exception Global_config_error of string

(** {2 Template Management} *)

let get_template_config source =
  let config_path = match source with
    | Local path -> Filename.concat path "spin.yaml"
  in
  match Template_config.decode_from_file config_path with
  | Ok config -> config
  | Error msg -> raise (Template_config_error msg)

(** {2 User Prompting and Context Building} *)

(** Validate user input based on field validation rules *)
let validate_input field_key rules input =
  match rules with
  | [] -> Ok input
  | _ ->
      let results = List.map (fun _rule ->
        (* TODO: This should use Jingoo. For now, we'll just use a placeholder that always succeeds *)
        Ok input
      ) rules in
      match List.find_opt Result.is_error results with
      | Some (Error msg) -> Error (Printf.sprintf "Validation failed for key '%s': %s" field_key msg)
      | _ -> Ok input

(** Prompt user for input based on field type *)
let prompt_user field_key field =
  match field.Template_config.field_type with
  | Input ->
      let validate = validate_input field_key field.validate in
      (match field.default with
       | Some default -> Ok (Inquire.input ~validate ~default field.prompt)
       | None -> Ok (Inquire.input ~validate field.prompt))
  | Select ->
      match field.options with
      | Some options -> Ok (Inquire.select ~options field.prompt)
      | None -> Error (Printf.sprintf "Select field type requires options for key: %s" field_key)

(** Process a single field in the template configuration *)
let process_field (key, field) =
  try
    match prompt_user key field with
    | Ok value -> Ok (key, value)
    | Error msg -> Error msg
  with
  | Sys_error msg -> Error (Printf.sprintf "Error during user input for key '%s': %s" key msg)

(** Build the template context from the configuration *)
let build_template_context config =
  let rec build_context_rec acc = function
    | [] -> Ok (List.rev acc)
    | field :: rest ->
        match process_field field with
        | Ok (key, value) -> build_context_rec ((key, value) :: acc) rest
        | Error msg -> Error msg
  in
  match build_context_rec [] config.Template_config.config with
  | Ok context -> context
  | Error msg -> raise (Context_build_error msg)

(** {2 Project Generation} *)

let is_binary_file filename =
  let ic = open_in_bin filename in
  let is_binary = 
    try 
      let chunk = really_input_string ic 1000 in
      close_in ic;
      String.contains chunk '\000'
    with _ -> 
      close_in ic;
      false
  in
  is_binary

let convert_to_jingoo_context (context) =
  List.map (fun (key, value) -> (key, Jingoo.Jg_types.Tstr value)) context

let process_content content context =
  Jingoo.Jg_template.from_string content ~models:(convert_to_jingoo_context context)

let get_destination file_templates filename context =
  match List.find_opt (fun (ft : Template_config.file_template) -> ft.source = filename) file_templates with
  | Some ft -> 
      (match ft.condition with
       | Some cond -> 
           if process_content cond context = "true" then
             Some (process_content ft.destination context)
           else
             None
       | None -> Some (process_content ft.destination context))
  | None -> Some filename

let rec mkdir_p ?perm dir =
  try
    match dir with
    | "." | ".." -> ()
    | _ ->
        let perm = match perm with Some p -> p | None -> 0o755 in
        Unix.mkdir dir perm
  with
  | Unix.Unix_error (EEXIST, _, _) -> ()
  | Unix.Unix_error (ENOENT, _, _) ->
      let parent = Filename.dirname dir in
      if String.equal parent dir then
        raise (Project_generation_error ("Could not create directory: " ^ dir))
      else (
        mkdir_p ?perm parent;
        mkdir_p ?perm dir
      )

let ensure_directory_exists dir =
  try
    mkdir_p dir
  with
  | Project_generation_error _ as e -> raise e
  | e -> raise (Project_generation_error ("Error ensuring directory exists: " ^ Printexc.to_string e))

let write_file path content =
  try
    Out_channel.with_open_bin path (fun oc -> 
      Out_channel.output_string oc content
    )
  with
  | Sys_error msg -> raise (Project_generation_error ("Error writing file: " ^ msg))

let process_file source_dir target_dir file_templates context filename =
  let template_dir = Filename.concat source_dir "template" in
  let source_path = Filename.concat template_dir filename in
  if is_binary_file source_path then
    ()
  else
    let content = In_channel.with_open_bin source_path In_channel.input_all in
    let processed_content = process_content content context in
    match get_destination file_templates filename context with
    | Some dest ->
        let target_path = Filename.concat target_dir dest in
        let target_dir = Filename.dirname target_path in
        ensure_directory_exists target_dir;
        write_file target_path processed_content
    | None -> ()

let remove_prefix prefix s =
  let prefix_length = String.length prefix in
  let s_length = String.length s in
  if s_length >= prefix_length && String.sub s 0 prefix_length = prefix then
    String.sub s prefix_length (s_length - prefix_length)
  else
    s

let rec process_directory source_dir target_dir file_templates context dir =
  try
    Sys.readdir dir
    |> Array.to_list
    |> List.iter (fun entry ->
        let path = Filename.concat dir entry in
        let relative_path = remove_prefix (Filename.concat source_dir "template" ^ Filename.dir_sep) path in
        if Sys.is_directory path then
          process_directory source_dir target_dir file_templates context path
        else
          process_file source_dir target_dir file_templates context relative_path
      )
  with
  | Sys_error msg -> raise (Project_generation_error ("Error processing directory: " ^ msg))

let execute_post_generation_action target_dir context = function
  | Template_config.Message msg -> 
      print_endline (process_content msg context)
  | Run cmds ->
      let processed_cmds = List.map (fun cmd -> process_content cmd context) cmds in
      let current_dir = Sys.getcwd () in
      Sys.chdir target_dir;
      try
        let exit_code = Sys.command (String.concat " && " processed_cmds) in
        Sys.chdir current_dir;
        if exit_code <> 0 then 
          raise (Project_generation_error "Post-generation command failed")
      with e ->
        Sys.chdir current_dir;
        raise (Project_generation_error ("Error executing post-generation action: " ^ Printexc.to_string e))

let execute_post_generation_actions config context target_dir =
  List.iter (fun action ->
    execute_post_generation_action target_dir context action
  ) config.Template_config.post_generation

let generate_project (source : template_source) (config : template_config) (context : template_context) (target_dir : string) =
  let source_dir = match source with Local path -> path in
  let template_dir = Filename.concat source_dir "template" in
  
  if not (Sys.file_exists template_dir && Sys.is_directory template_dir) then
    raise (Project_generation_error "Template directory not found")
  else begin
    ensure_directory_exists target_dir;
    process_directory source_dir target_dir config.file_templates context template_dir;
    execute_post_generation_actions config context target_dir
  end

let get_global_config () = 
  raise (Global_config_error "TODO: Implement get_global_config")

let set_global_config _key _value = 
  raise (Global_config_error "TODO: Implement set_global_config")

let resolve_template_source source = Local source
