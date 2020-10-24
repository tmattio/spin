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
    | Generators

  type t =
    { source : Source.t
    ; ignore_configs : bool
    ; ignore_actions : bool
    ; ignore_example_commands : bool
    ; ignore_generators : bool
    }

  let decode_overwrite sexp =
    match sexp with
    | Sexp.Atom "configs" ->
      Ok Configs
    | Sexp.Atom "actions" ->
      Ok Actions
    | Sexp.Atom "example_commands" ->
      Ok Example_commands
    | Sexp.Atom "generators" ->
      Ok Generators
    | Sexp.Atom _ ->
      decoder_error ~msg:Errors.invalid_overwite sexp
    | Sexp.List _ ->
      decoder_error ~msg:Errors.expected_string sexp

  let decode =
    let open Decoder in
    let+ source = Source.decode
    and+ overwrites = field_opt "overwrites" ~f:(list decode_overwrite) in
    let overwrites = Option.value overwrites ~default:[] in
    let ignore_configs =
      List.exists overwrites ~f:(function Configs -> true | _ -> false)
    in
    let ignore_actions =
      List.exists overwrites ~f:(function Actions -> true | _ -> false)
    in
    let ignore_example_commands =
      List.exists overwrites ~f:(function
          | Example_commands ->
            true
          | _ ->
            false)
    in
    let ignore_generators =
      List.exists overwrites ~f:(function Generators -> true | _ -> false)
    in
    { source
    ; ignore_configs
    ; ignore_actions
    ; ignore_example_commands
    ; ignore_generators
    }
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
      ; "one file", Decoder.map ~f:List.return Decoder.string
      ]
end

module Expr = struct
  type t =
    | Var of string
    | Function of func
    | String of string

  and func =
    | If of t * t * t
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
    | Sexp.Atom s when String.equal (String.prefix s 1) ":" ->
      Ok (Var (String.drop_prefix s 1))
    | Sexp.Atom s when String.equal (String.prefix s 2) "\\:" ->
      Ok (String (String.drop_prefix s 1))
    | Sexp.Atom s ->
      Ok (String s)
    | Sexp.List (Sexp.Atom ("if" as name) :: args) as sexp ->
      decode_fn3 name args ~sexp ~ctor:(fun a b c -> If (a, b, c))
    | Sexp.List (Sexp.Atom ("eq" as name) :: args) as sexp ->
      decode_fn2 name args ~sexp ~ctor:(fun a b -> Eq (a, b))
    | Sexp.List (Sexp.Atom ("neq" as name) :: args) as sexp ->
      decode_fn2 name args ~sexp ~ctor:(fun a b -> Neq (a, b))
    | Sexp.List (Sexp.Atom ("not" as name) :: args) as sexp ->
      decode_fn1 name args ~sexp ~ctor:(fun a -> Not a)
    | Sexp.List (Sexp.Atom ("slugify" as name) :: args) as sexp ->
      decode_fn1 name args ~sexp ~ctor:(fun a -> Slugify a)
    | Sexp.List (Sexp.Atom ("upper" as name) :: args) as sexp ->
      decode_fn1 name args ~sexp ~ctor:(fun a -> Upper a)
    | Sexp.List (Sexp.Atom ("lower" as name) :: args) as sexp ->
      decode_fn1 name args ~sexp ~ctor:(fun a -> Lower a)
    | Sexp.List (Sexp.Atom ("snake_case" as name) :: args) as sexp ->
      decode_fn1 name args ~sexp ~ctor:(fun a -> Snake_case a)
    | Sexp.List (Sexp.Atom ("camel_case" as name) :: args) as sexp ->
      decode_fn1 name args ~sexp ~ctor:(fun a -> Camel_case a)
    | Sexp.List (Sexp.Atom ("trim" as name) :: args) as sexp ->
      decode_fn1 name args ~sexp ~ctor:(fun a -> Trim a)
    | Sexp.List (Sexp.Atom ("first_char" as name) :: args) as sexp ->
      decode_fn1 name args ~sexp ~ctor:(fun a -> First_char a)
    | Sexp.List (Sexp.Atom ("last_char" as name) :: args) as sexp ->
      decode_fn1 name args ~sexp ~ctor:(fun a -> Last_char a)
    | Sexp.List (Sexp.Atom ("run" as name) :: args) as sexp ->
      let open Result.Let_syntax in
      (match args with
      | e1 :: rest ->
        let+ d1 = decode e1
        and+ d2 =
          List.fold_left rest ~init:(Ok []) ~f:(fun acc el ->
              let* acc = acc in
              let+ decoded = decode el in
              decoded :: acc)
        in
        Function (Run (d1, d2))
      | _ ->
        decoder_error
          ~msg:
            (Printf.sprintf
               "The function %S expected exactly one argument."
               name)
          sexp)
    | Sexp.List (Sexp.Atom "concat" :: args) ->
      let open Result.Let_syntax in
      let+ d_args =
        List.fold_left args ~init:(Ok []) ~f:(fun acc el ->
            let* acc = acc in
            let+ decoded = decode el in
            decoded :: acc)
      in
      Function (Concat (List.rev d_args))
    | Sexp.List (Sexp.Atom fn :: _) as sexp ->
      decoder_error
        ~msg:(Printf.sprintf "The function %S does not exist." fn)
        sexp
    | (Sexp.List (Sexp.List _ :: _) | Sexp.List []) as sexp ->
      decoder_error
        ~msg:(Printf.sprintf "The expression does not have a valid format.")
        sexp

  and decode_fn1 ~sexp ~ctor name =
    let open Result.Let_syntax in
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
    let open Result.Let_syntax in
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
    let open Result.Let_syntax in
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
    let open Decoder.Let_syntax in
    let+ message = Decoder.field "prompt" ~f:Decoder.string in
    Input { message }

  let decode_select =
    let open Decoder.Let_syntax in
    let+ message = Decoder.field "prompt" ~f:Decoder.string
    and+ values = Decoder.field "values" ~f:Decoder.(list string) in
    Select { message; values }

  let decode_confirm =
    let open Decoder.Let_syntax in
    let+ message = Decoder.field "prompt" ~f:Decoder.string in
    Confirm { message }

  let decode_prompt =
    Decoder.one_of_opt
      [ "input", Decoder.field "input" ~f:decode_input
      ; "select", Decoder.field "select" ~f:decode_select
      ; "confirm", Decoder.field "confirm" ~f:decode_confirm
      ]

  let decode_rule =
    let open Result.Let_syntax in
    function
    | Sexp.List [ message; expr ] ->
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
    | Sexp.List (Sexp.Atom name :: rest) ->
      let open Result.Let_syntax in
      let optional_fields = Sexp.List rest in
      let+ prompt = decode_prompt optional_fields
      and+ default = Decoder.field_opt "default" ~f:Expr.decode optional_fields
      and+ rules =
        Decoder.field_opt
          "rules"
          ~f:
            (Decoder.one_of
               [ "n rules", Decoder.list decode_rule
               ; "one rule", Decoder.map ~f:List.return decode_rule
               ])
          optional_fields
      and+ enabled_if =
        Decoder.field_opt "enabled_if" ~f:Expr.decode optional_fields
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
    | Refmt of Expr.t list

  type t =
    { actions : action list
    ; message : Expr.t option
    ; enabled_if : Expr.t option
    }

  let decode_run_action =
    let open Result.Let_syntax in
    function
    | Sexp.List (Sexp.Atom name :: rest) ->
      let+ args = Decoder.list Decoder.string (Sexp.List rest) in
      Run { name; args }
    | sexp ->
      decoder_error
        ~msg:
          "Invalid action format. Expected an s-expression of the form (<name> \
           <args>...)"
        sexp

  let decode_refmt_action sexp =
    let open Result.Let_syntax in
    let+ files =
      Decoder.one_of
        [ "string", Decoder.map Expr.decode ~f:List.return
        ; ("string list", Decoder.(list Expr.decode))
        ]
        sexp
    in
    Refmt files

  let decode_action =
    Decoder.one_of
      [ "run", Decoder.field "run" ~f:decode_run_action
      ; "refmt", Decoder.field "refmt" ~f:decode_refmt_action
      ]

  let decode =
    let open Decoder.Let_syntax in
    let+ actions =
      Decoder.field
        "actions"
        ~f:
          (Decoder.one_of
             [ "n actions", Decoder.list decode_action
             ; "one action", Decoder.map ~f:List.return decode_action
             ])
    and+ message = Decoder.field_opt "message" ~f:Expr.decode
    and+ enabled_if = Decoder.field_opt "enabled_if" ~f:Expr.decode in
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
      ; "string", Decoder.map Decoder.string ~f:List.return
      ]
      sexp

  let decode =
    let open Decoder.Let_syntax in
    let+ files = Decoder.field "files" ~f:decode_files
    and+ enabled_if = Decoder.field_opt "enabled_if" ~f:Expr.decode in
    { files; enabled_if }
end

module Example_command = struct
  type t =
    { name : string
    ; description : string
    ; enabled_if : Expr.t option
    }

  let decode =
    let open Decoder.Let_syntax in
    let+ name = Decoder.field "name" ~f:Decoder.string
    and+ description = Decoder.field "description" ~f:Decoder.string
    and+ enabled_if = Decoder.field_opt "enabled_if" ~f:Expr.decode in
    { name; description; enabled_if }
end

module Example_commands = struct
  type t = Example_command.t list

  type command =
    { name : string
    ; description : string
    }

  let decode_command = function
    | Sexp.List [ Sexp.Atom name; Sexp.Atom description ] ->
      Ok { name; description }
    | sexp ->
      decoder_error
        ~msg:"Expected an s-expression with the form (<name> <description>)"
        sexp

  let decode_commands = Decoder.list decode_command

  let decode =
    let open Decoder.Let_syntax in
    let+ commands = Decoder.field "commands" ~f:decode_commands
    and+ enabled_if = Decoder.field_opt "enabled_if" ~f:Expr.decode in
    List.map commands ~f:(fun cmd ->
        Example_command.
          { name = cmd.name; description = cmd.description; enabled_if })
end

module Generator = struct
  type file =
    { source : string
    ; destination : Expr.t
    }

  type t =
    { name : string
    ; description : string
    ; configurations : Configuration.t list
    ; pre_gen_actions : Actions.t list
    ; post_gen_actions : Actions.t list
    ; files : file list
    ; message : Expr.t option
    }

  let decode_file = function
    | Sexp.List [ Sexp.Atom source; destination ] ->
      let open Result.Let_syntax in
      let+ destination = Expr.decode destination in
      { source; destination }
    | sexp ->
      decoder_error
        ~msg:"Expected an s-expression with the form (<file> <expression>)"
        sexp

  let decode_files =
    Decoder.one_of
      [ "n files", Decoder.list decode_file
      ; "one file", Decoder.map ~f:List.return decode_file
      ]

  let decode =
    let open Decoder.Let_syntax in
    let+ name = Decoder.field "name" ~f:Template_name.decode
    and+ description = Decoder.field "description" ~f:Description.decode
    and+ configurations = Decoder.fields "config" ~f:Configuration.decode
    and+ pre_gen_actions = Decoder.fields "pre_gen" ~f:Actions.decode
    and+ post_gen_actions = Decoder.fields "post_gen" ~f:Actions.decode
    and+ files = Decoder.field_opt "files" ~f:decode_files
    and+ message = Decoder.field_opt "message" ~f:Expr.decode in
    { name
    ; description
    ; configurations
    ; pre_gen_actions
    ; post_gen_actions
    ; files = Option.value files ~default:[]
    ; message
    }
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
  ; generators : Generator.t list
  }

let decode =
  let open Decoder.Let_syntax in
  let+ name = Decoder.field "name" ~f:Template_name.decode
  and+ description = Decoder.field "description" ~f:Description.decode
  and+ base_template = Decoder.field_opt "inherit" ~f:Base_template.decode
  and+ parse_binaries =
    Decoder.field_opt "parse_binaries" ~f:Parse_binaries.decode
  and+ raw_files = Decoder.field_opt "raw_files" ~f:Raw_files.decode
  and+ configurations = Decoder.fields "config" ~f:Configuration.decode
  and+ pre_gen_actions = Decoder.fields "pre_gen" ~f:Actions.decode
  and+ post_gen_actions = Decoder.fields "post_gen" ~f:Actions.decode
  and+ ignore_file_rules = Decoder.fields "ignore" ~f:Ignore_rule.decode
  and+ example_commands_list =
    Decoder.fields "example_commands" ~f:Example_commands.decode
  and+ example_command_list =
    Decoder.fields "example_command" ~f:Example_command.decode
  and+ generators = Decoder.fields "generator" ~f:Generator.decode in
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
  ; generators
  }
