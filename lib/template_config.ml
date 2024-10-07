(* Template_config.ml *)

type template_expression = string 

type validation_rule = { description : string; check : template_expression }

type config_field_type = Input | Select 

type config_field = {
  prompt : string;
  field_type : config_field_type;
  default : template_expression option;
  options : string list option;
  validate : validation_rule list;
}

type file_template = {
  source : string;
  destination : string;
  condition : template_expression option;
}

type post_generation_action = Message of string | Run of string list

type config = (string * config_field) list 

type t = {
  name : string;
  description : string;
  config : config;
  file_templates : file_template list;
  post_generation : post_generation_action list;
}

let error_to_string = function
  | `InvalidYamlFormat s -> "Invalid YAML format: " ^ s
  | `MissingField s -> "Missing field: " ^ s
  | `InvalidFieldType (field, expected) -> 
      Printf.sprintf "Invalid field type for '%s'. Expected %s" field expected
  | `InvalidOption s -> "Invalid option: " ^ s
  | `Other s -> "Error: " ^ s

(* Custom implementation of Result.all with string errors *)
module Result = struct
  include Result

  let all results =
    List.fold_left
      (fun acc result ->
         match acc, result with
         | Ok acc_list, Ok x -> Ok (x :: acc_list)
         | Error e, _ -> Error e
         | _, Error e -> Error e)
      (Ok [])
      results
    |> Result.map List.rev
end

let decode_template_expression s = s

let decode_validation_rule yaml =
  match yaml with
  | `O [("description", `String desc); ("check", `String check)] ->
      Ok { description = desc; check = decode_template_expression check }
  | _ -> Error "Invalid validation rule format"

let decode_config_field_type = function
  | `String "input" -> Ok Input
  | `String "select" -> Ok Select
  | `String s -> Error (Printf.sprintf "Invalid config field type: %s" s)
  | _ -> Error "Invalid field type: expected string"

let decode_config_field yaml =
  match yaml with
  | `O fields ->
      let ( let* ) = Result.bind in
      let* prompt = 
        match List.assoc_opt "prompt" fields with
        | Some (`String s) -> Ok s
        | Some _ -> Error "Invalid field type for 'prompt'. Expected string"
        | None -> Error "Missing field: prompt"
      in
      let* field_type = 
        match List.assoc_opt "type" fields with
        | Some t -> decode_config_field_type t
        | None -> Error "Missing field: type"
      in
      let* default = 
        match List.assoc_opt "default" fields with
        | Some (`String s) -> Ok (Some (decode_template_expression s))
        | Some _ -> Error "Invalid field type for 'default'. Expected string"
        | None -> Ok None
      in
      let* options = 
        match List.assoc_opt "options" fields with
        | Some (`A opts) -> 
            opts 
            |> List.map (function 
                | `String s -> Ok s 
                | _ -> Error "Invalid option type. Expected string")
            |> Result.all
            |> Result.map Option.some
        | Some _ -> Error "Invalid field type for 'options'. Expected array"
        | None -> Ok None
      in
      let* validate = 
        match List.assoc_opt "validate" fields with
        | Some (`A rules) -> 
            rules 
            |> List.map decode_validation_rule
            |> Result.all
        | Some _ -> Error "Invalid field type for 'validate'. Expected array"
        | None -> Ok []
      in
      Ok { prompt; field_type; default; options; validate }
  | _ -> Error "Invalid config field format"

let decode_file_template yaml =
  match yaml with
  | `O fields ->
      let ( let* ) = Result.bind in
      let* source = 
        match List.assoc_opt "source" fields with
        | Some (`String s) -> Ok s
        | Some _ -> Error "Invalid field type for 'source'. Expected string"
        | None -> Error "Missing field: source"
      in
      let* destination = 
        match List.assoc_opt "destination" fields with
        | Some (`String s) -> Ok s
        | Some _ -> Error "Invalid field type for 'destination'. Expected string"
        | None -> Error "Missing field: destination"
      in
      let* condition = 
        match List.assoc_opt "when" fields with
        | Some (`String s) -> Ok (Some (decode_template_expression s))
        | Some _ -> Error "Invalid field type for 'when'. Expected string"
        | None -> Ok None
      in
      Ok { source; destination; condition }
  | _ -> Error "Invalid file template format"

let decode_post_generation_action yaml =
  match yaml with
  | `O [("message", `String msg)] -> Ok (Message msg)
  | `O [("run", `A cmds)] ->
      cmds 
      |> List.map (function 
          | `String cmd -> Ok cmd 
          | _ -> Error "Invalid command type. Expected string")
      |> Result.all
      |> Result.map (fun cmds -> Run cmds)
  | _ -> Error "Invalid post-generation action format"

let decode_config yaml =
  match yaml with
  | `O fields ->
      fields
      |> List.map (fun (k, v) -> 
          decode_config_field v 
          |> Result.map (fun cf -> (k, cf)))
      |> Result.all
  | _ -> Error "Invalid config format"

let decode yaml =
  match yaml with
  | `O fields ->
      let ( let* ) = Result.bind in
      let* name = 
        match List.assoc_opt "name" fields with
        | Some (`String s) -> Ok s
        | Some _ -> Error "Invalid field type for 'name'. Expected string"
        | None -> Error "Missing field: name"
      in
      let* description = 
        match List.assoc_opt "description" fields with
        | Some (`String s) -> Ok s
        | Some _ -> Error "Invalid field type for 'description'. Expected string"
        | None -> Error "Missing field: description"
      in
      let* config = 
        match List.assoc_opt "config" fields with
        | Some c -> decode_config c
        | None -> Error "Missing field: config"
      in
      let* file_templates = 
        match List.assoc_opt "file_templates" fields with
        | Some (`A templates) -> 
            templates 
            |> List.map decode_file_template
            |> Result.all
        | Some _ -> Error "Invalid field type for 'file_templates'. Expected array"
        | None -> Error "Missing field: file_templates"
      in
      let* post_generation = 
        match List.assoc_opt "post_generation" fields with
        | Some (`A actions) -> 
            actions 
            |> List.map decode_post_generation_action
            |> Result.all
        | Some _ -> Error "Invalid field type for 'post_generation'. Expected array"
        | None -> Error "Missing field: post_generation"
      in
      Ok { name; description; config; file_templates; post_generation }
  | _ -> Error "Invalid YAML format"

let decode_from_string s =
  try
    let yaml = Yaml.of_string_exn s in
    decode yaml
  with
  | Invalid_argument e -> Error ("YAML parsing error: " ^ e)
  | e -> Error ("Unexpected error: " ^ Printexc.to_string e)

let decode_from_file filename =
  try
    let ch = open_in filename in
    let contents = really_input_string ch (in_channel_length ch) in
    close_in ch;
    decode_from_string contents
  with
  | Sys_error msg -> Error ("File error: " ^ msg)
  | e -> Error ("Unexpected error while reading file: " ^ Printexc.to_string e)
