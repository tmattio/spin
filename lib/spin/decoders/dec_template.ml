open Dec_common

let decoder_error ~msg sexp = Error (Decoder.Decoder_error (msg, Some sexp))

module Description = struct
  type t = string

  let decode = Decoder.string
end

module Base_template = struct
  module Errors = struct
    let invalid_overwite =
      {|The overwite does not exist. Supported overwrites are "configs", "ignores", "post_gens", "pre_gens" and "example_commands"|}

    let expected_string = "Expected an string with the name of the overwrite."
  end

  type overwrite =
    | Configs
    | Actions
    | Example_commands

  type t =
    { source : Source.t
    ; ignore_configs : bool
    ; ignore_actions : bool
    ; ignore_example_commands : bool
    }

  let decode_overwrite sexp =
    match sexp with
    | Sexplib.Sexp.Atom "configs" ->
      Ok Configs
    | Sexplib.Sexp.Atom "actions" ->
      Ok Actions
    | Sexplib.Sexp.Atom "example_commands" ->
      Ok Example_commands
    | Sexplib.Sexp.Atom _ ->
      decoder_error ~msg:Errors.invalid_overwite sexp
    | Sexplib.Sexp.List _ ->
      decoder_error ~msg:Errors.expected_string sexp

  let decode =
    let open Decoder in
    let+ source = Source.decode
    and+ overwrites = field_opt "overwrites" (list decode_overwrite) in
    let overwrites = Option.value overwrites ~default:[] in
    let ignore_configs =
      List.exists (function Configs -> true | _ -> false) overwrites
    in
    let ignore_actions =
      List.exists (function Actions -> true | _ -> false) overwrites
    in
    let ignore_example_commands =
      List.exists (function Example_commands -> true | _ -> false) overwrites
    in
    { source; ignore_configs; ignore_actions; ignore_example_commands }
end

module Parse_binaries = struct
  type t = bool

  let decode = Decoder.bool
end

module Raw_files = struct
  type t = string list

  let decode =
    Decoder.one_of
      [ "n files", Decoder.list Decoder.string
      ; "one file", Decoder.map (fun x -> [ x ]) Decoder.string
      ]
end

module Expr = struct
  type t =
    | Var of string
    | Function of func
    | String of string

  and func =
    | If of t * t * t
    | And of t * t
    | Or of t * t
    | Eq of t * t
    | Neq of t * t
    | Not of t
    | Slugify of t
    | Upper of t
    | Lower of t
    | Snake_case of t
    | Camel_case of t
    | Run of t * t list
    | Trim of t
    | First_char of t
    | Last_char of t
    | Concat of t list

  let rec decode = function
    | Sexplib.Sexp.Atom s when String.equal (String.prefix s 1) ":" ->
      Ok (Var (String.drop_prefix s 1))
    | Sexplib.Sexp.Atom s when String.equal (String.prefix s 2) "\\:" ->
      Ok (String (String.drop_prefix s 1))
    | Sexplib.Sexp.Atom s ->
      Ok (String s)
    | Sexplib.Sexp.List (Sexplib.Sexp.Atom ("if" as name) :: args) as sexp ->
      decode_fn3 name args ~sexp ~ctor:(fun a b c -> If (a, b, c))
    | Sexplib.Sexp.List (Sexplib.Sexp.Atom ("and" as name) :: args) as sexp ->
      decode_fn2 name args ~sexp ~ctor:(fun a b -> And (a, b))
    | Sexplib.Sexp.List (Sexplib.Sexp.Atom ("or" as name) :: args) as sexp ->
      decode_fn2 name args ~sexp ~ctor:(fun a b -> Or (a, b))
    | Sexplib.Sexp.List (Sexplib.Sexp.Atom ("eq" as name) :: args) as sexp ->
      decode_fn2 name args ~sexp ~ctor:(fun a b -> Eq (a, b))
    | Sexplib.Sexp.List (Sexplib.Sexp.Atom ("neq" as name) :: args) as sexp ->
      decode_fn2 name args ~sexp ~ctor:(fun a b -> Neq (a, b))
    | Sexplib.Sexp.List (Sexplib.Sexp.Atom ("not" as name) :: args) as sexp ->
      decode_fn1 name args ~sexp ~ctor:(fun a -> Not a)
    | Sexplib.Sexp.List (Sexplib.Sexp.Atom ("slugify" as name) :: args) as sexp
      ->
      decode_fn1 name args ~sexp ~ctor:(fun a -> Slugify a)
    | Sexplib.Sexp.List (Sexplib.Sexp.Atom ("upper" as name) :: args) as sexp ->
      decode_fn1 name args ~sexp ~ctor:(fun a -> Upper a)
    | Sexplib.Sexp.List (Sexplib.Sexp.Atom ("lower" as name) :: args) as sexp ->
      decode_fn1 name args ~sexp ~ctor:(fun a -> Lower a)
    | Sexplib.Sexp.List (Sexplib.Sexp.Atom ("snake_case" as name) :: args) as
      sexp ->
      decode_fn1 name args ~sexp ~ctor:(fun a -> Snake_case a)
    | Sexplib.Sexp.List (Sexplib.Sexp.Atom ("camel_case" as name) :: args) as
      sexp ->
      decode_fn1 name args ~sexp ~ctor:(fun a -> Camel_case a)
    | Sexplib.Sexp.List (Sexplib.Sexp.Atom ("trim" as name) :: args) as sexp ->
      decode_fn1 name args ~sexp ~ctor:(fun a -> Trim a)
    | Sexplib.Sexp.List (Sexplib.Sexp.Atom ("first_char" as name) :: args) as
      sexp ->
      decode_fn1 name args ~sexp ~ctor:(fun a -> First_char a)
    | Sexplib.Sexp.List (Sexplib.Sexp.Atom ("last_char" as name) :: args) as
      sexp ->
      decode_fn1 name args ~sexp ~ctor:(fun a -> Last_char a)
    | Sexplib.Sexp.List (Sexplib.Sexp.Atom ("run" as name) :: args) as sexp ->
      let open Result.Syntax in
      (match args with
      | e1 :: rest ->
        let+ d1 = decode e1
        and+ d2 =
          List.fold_left
            (fun acc el ->
              let* acc = acc in
              let+ decoded = decode el in
              decoded :: acc)
            (Ok [])
            rest
        in
        Function (Run (d1, d2))
      | _ ->
        decoder_error
          ~msg:
            (Printf.sprintf
               "The function %S expected exactly one argument."
               name)
          sexp)
    | Sexplib.Sexp.List (Sexplib.Sexp.Atom "concat" :: args) ->
      let open Result.Syntax in
      let+ d_args =
        List.fold_left
          (fun acc el ->
            let* acc = acc in
            let+ decoded = decode el in
            decoded :: acc)
          (Ok [])
          args
      in
      Function (Concat (List.rev d_args))
    | Sexplib.Sexp.List (Sexplib.Sexp.Atom fn :: _) as sexp ->
      decoder_error
        ~msg:(Printf.sprintf "The function %S does not exist." fn)
        sexp
    | (Sexplib.Sexp.List (Sexplib.Sexp.List _ :: _) | Sexplib.Sexp.List []) as
      sexp ->
      decoder_error
        ~msg:(Printf.sprintf "The expression does not have a valid format.")
        sexp

  and decode_fn1 ~sexp ~ctor name =
    let open Result.Syntax in
    function
    | [ e1 ] ->
      let+ d1 = decode e1 in
      Function (ctor d1)
    | _ ->
      decoder_error
        ~msg:
          (Printf.sprintf "The function %S expected exactly one argument." name)
        sexp

  and decode_fn2 ~sexp ~ctor name =
    let open Result.Syntax in
    function
    | [ e1; e2 ] ->
      let+ d1 = decode e1
      and+ d2 = decode e2 in
      Function (ctor d1 d2)
    | _ ->
      decoder_error
        ~msg:
          (Printf.sprintf
             "The function %S expected exactly two arguments."
             name)
        sexp

  and decode_fn3 ~sexp ~ctor name =
    let open Result.Syntax in
    function
    | [ e1; e2; e3 ] ->
      let+ d1 = decode e1
      and+ d2 = decode e2
      and+ d3 = decode e3 in
      Function (ctor d1 d2 d3)
    | _ ->
      decoder_error
        ~msg:
          (Printf.sprintf
             "The function %S expected exactly three arguments."
             name)
        sexp
end

module Configuration = struct
  type input_t = { message : string }

  type select_t =
    { message : string
    ; values : string list
    }

  type confirm_t = { message : string }

  type prompt =
    | Input of input_t
    | Select of select_t
    | Confirm of confirm_t

  type rule =
    { message : Expr.t
    ; expr : Expr.t
    }

  type t =
    { name : string
    ; prompt : prompt option
    ; default : Expr.t option
    ; rules : rule list
    ; enabled_if : Expr.t option
    }

  let decode_input =
    let open Decoder.Syntax in
    let+ message = Decoder.field "prompt" Decoder.string in
    Input { message }

  let decode_select =
    let open Decoder.Syntax in
    let+ message = Decoder.field "prompt" Decoder.string
    and+ values = Decoder.field "values" Decoder.(list string) in
    Select { message; values }

  let decode_confirm =
    let open Decoder.Syntax in
    let+ message = Decoder.field "prompt" Decoder.string in
    Confirm { message }

  let decode_prompt =
    Decoder.one_of_opt
      [ "input", Decoder.field "input" decode_input
      ; "select", Decoder.field "select" decode_select
      ; "confirm", Decoder.field "confirm" decode_confirm
      ]

  let decode_rule =
    let open Result.Syntax in
    function
    | Sexplib.Sexp.List [ message; expr ] ->
      let+ message = Expr.decode message
      and+ expr = Expr.decode expr in
      { message; expr }
    | sexp ->
      decoder_error
        ~msg:
          "Invalid rule format. Expected an s-expression of the form \
           (<message> <expression>)"
        sexp

  let decode = function
    | Sexplib.Sexp.List (Sexplib.Sexp.Atom name :: rest) ->
      let open Result.Syntax in
      let optional_fields = Sexplib.Sexp.List rest in
      let+ prompt = decode_prompt optional_fields
      and+ default = Decoder.field_opt "default" Expr.decode optional_fields
      and+ rules =
        Decoder.field_opt
          "rules"
          (Decoder.one_of
             [ "n rules", Decoder.list decode_rule
             ; "one rule", Decoder.map (fun x -> [ x ]) decode_rule
             ])
          optional_fields
      and+ enabled_if =
        Decoder.field_opt "enabled_if" Expr.decode optional_fields
      in
      let rules = Option.value rules ~default:[] in
      { name; prompt; default; rules; enabled_if }
    | sexp ->
      decoder_error
        ~msg:
          "Invalid config format, expected an expression of the form (<name> \
           <optional-fields>...)"
        sexp
end

module Actions = struct
  type command =
    { name : string
    ; args : string list
    }

  type action =
    | Run of command
    | Install
    | Build
    | Refmt of Expr.t list

  type t =
    { actions : action list
    ; message : Expr.t option
    ; enabled_if : Expr.t option
    }

  let decode_run_action =
    let open Result.Syntax in
    function
    | Sexplib.Sexp.List (Sexplib.Sexp.Atom name :: rest) ->
      let+ args = Decoder.list Decoder.string (Sexplib.Sexp.List rest) in
      Run { name = String.trim name; args = List.map String.trim args }
    | sexp ->
      decoder_error
        ~msg:
          "Invalid action format. Expected an s-expression of the form (<name> \
           <args>...)"
        sexp

  let decode_refmt_action sexp =
    let open Result.Syntax in
    let+ files =
      Decoder.one_of
        [ "string", Decoder.map (fun x -> [ x ]) Expr.decode
        ; ("string list", Decoder.(list Expr.decode))
        ]
        sexp
    in
    Refmt files

  let decode_install_action _sexp = Ok Install

  let decode_build_action _sexp = Ok Build

  let decode_action =
    Decoder.one_of
      [ "run", Decoder.field "run" decode_run_action
      ; "install", Decoder.field "install" decode_install_action
      ; "build", Decoder.field "build" decode_build_action
      ; "refmt", Decoder.field "refmt" decode_refmt_action
      ]

  let decode =
    let open Decoder.Syntax in
    let+ actions =
      Decoder.field
        "actions"
        (Decoder.one_of
           [ "n actions", Decoder.list decode_action
           ; "one action", Decoder.map (fun x -> [ x ]) decode_action
           ])
    and+ message = Decoder.field_opt "message" Expr.decode
    and+ enabled_if = Decoder.field_opt "enabled_if" Expr.decode in
    { actions; message; enabled_if }
end

module Ignore_rule = struct
  type t =
    { files : string list
    ; enabled_if : Expr.t option
    }

  let decode_files sexp =
    Decoder.one_of
      [ ("string list", Decoder.(list string))
      ; "string", Decoder.map (fun x -> [ x ]) Decoder.string
      ]
      sexp

  let decode =
    let open Decoder.Syntax in
    let+ files = Decoder.field "files" decode_files
    and+ enabled_if = Decoder.field_opt "enabled_if" Expr.decode in
    { files; enabled_if }
end

module Example_command = struct
  type t =
    { name : string
    ; description : string
    ; enabled_if : Expr.t option
    }

  let decode =
    let open Decoder.Syntax in
    let+ name = Decoder.field "name" Decoder.string
    and+ description = Decoder.field "description" Decoder.string
    and+ enabled_if = Decoder.field_opt "enabled_if" Expr.decode in
    { name; description; enabled_if }
end

module Example_commands = struct
  type t = Example_command.t list

  type command =
    { name : string
    ; description : string
    }

  let decode_command = function
    | Sexplib.Sexp.List
        [ Sexplib.Sexp.Atom name; Sexplib.Sexp.Atom description ] ->
      Ok { name; description }
    | sexp ->
      decoder_error
        ~msg:"Expected an s-expression with the form (<name> <description>)"
        sexp

  let decode_commands = Decoder.list decode_command

  let decode =
    let open Decoder.Syntax in
    let+ (commands : command list) = Decoder.field "commands" decode_commands
    and+ enabled_if = Decoder.field_opt "enabled_if" Expr.decode in
    List.map
      (fun (cmd : command) ->
        Example_command.
          { name = cmd.name; description = cmd.description; enabled_if })
      commands
end

type t =
  { name : string
  ; description : string
  ; base_template : Base_template.t option
  ; parse_binaries : bool option
  ; raw_files : string list option
  ; configurations : Configuration.t list
  ; pre_gen_actions : Actions.t list
  ; post_gen_actions : Actions.t list
  ; ignore_file_rules : Ignore_rule.t list
  ; example_commands : Example_command.t list
  }

let decode =
  let open Decoder.Syntax in
  let+ name = Decoder.field "name" Template_name.decode
  and+ description = Decoder.field "description" Description.decode
  and+ base_template = Decoder.field_opt "inherit" Base_template.decode
  and+ parse_binaries = Decoder.field_opt "parse_binaries" Parse_binaries.decode
  and+ raw_files = Decoder.field_opt "raw_files" Raw_files.decode
  and+ configurations = Decoder.fields "config" Configuration.decode
  and+ pre_gen_actions = Decoder.fields "pre_gen" Actions.decode
  and+ post_gen_actions = Decoder.fields "post_gen" Actions.decode
  and+ ignore_file_rules = Decoder.fields "ignore" Ignore_rule.decode
  and+ example_commands_list =
    Decoder.fields "example_commands" Example_commands.decode
  and+ example_command_list =
    Decoder.fields "example_command" Example_command.decode
  in
  let example_commands =
    example_command_list @ List.concat example_commands_list
  in
  { name
  ; description
  ; base_template
  ; parse_binaries
  ; raw_files
  ; configurations
  ; pre_gen_actions
  ; post_gen_actions
  ; ignore_file_rules
  ; example_commands
  }
