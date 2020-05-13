exception Refmt_error of string

type ast =
  | Impl of Reason_toolchain_conf.Parsetree.structure
  | Intf of Reason_toolchain_conf.Parsetree.signature_item list

type parse_output =
  { ast : ast
  ; comments : Reason_comment.t list
  ; parsed_as_ml : bool
  }

let parse filename =
  if Filename.check_suffix filename ".re" then
    let lexbuf = Reason_toolchain.setup_lexbuf false filename in
    let impl = Reason_toolchain.RE.implementation_with_comments in
    let ast, comments = impl lexbuf in
    { ast = Impl ast; comments; parsed_as_ml = false }
  else if Filename.check_suffix filename ".rei" then
    let lexbuf = Reason_toolchain.setup_lexbuf false filename in
    let intf = Reason_toolchain.RE.interface_with_comments in
    let ast, comments = intf lexbuf in
    { ast = Intf ast; comments; parsed_as_ml = false }
  else if Filename.check_suffix filename ".ml" then
    let lexbuf = Reason_toolchain.setup_lexbuf false filename in
    let impl = Reason_toolchain.ML.implementation_with_comments in
    let ast, comments = impl lexbuf in
    { ast = Impl ast; comments; parsed_as_ml = false }
  else if Filename.check_suffix filename ".mli" then
    let lexbuf = Reason_toolchain.setup_lexbuf false filename in
    let intf = Reason_toolchain.ML.interface_with_comments in
    let ast, comments = intf lexbuf in
    { ast = Intf ast; comments; parsed_as_ml = false }
  else
    raise (Refmt_error "The file extension is not valid.")

let print filename parse_output output_formatter =
  if Filename.check_suffix filename ".re" then
    match parse_output.ast with
    | Impl impl ->
      Reason_toolchain.RE.print_implementation_with_comments
        output_formatter
        (impl, parse_output.comments)
    | Intf _ ->
      raise (Refmt_error "Cannot print an implementation from an interface")
  else if Filename.check_suffix filename ".rei" then
    match parse_output.ast with
    | Intf intf ->
      Reason_toolchain.RE.print_interface_with_comments
        output_formatter
        (intf, parse_output.comments)
    | Impl _ ->
      raise (Refmt_error "Cannot print an interface from an implementation")
  else if Filename.check_suffix filename ".ml" then
    match parse_output.ast with
    | Impl impl ->
      Reason_toolchain.ML.print_implementation_with_comments
        output_formatter
        (impl, parse_output.comments)
    | Intf _ ->
      raise (Refmt_error "Cannot print an implementation from an interface")
  else if Filename.check_suffix filename ".mli" then
    match parse_output.ast with
    | Intf intf ->
      Reason_toolchain.ML.print_interface_with_comments
        output_formatter
        (intf, parse_output.comments)
    | Impl _ ->
      raise (Refmt_error "Cannot print an interface from an implementation")
  else
    raise (Refmt_error "The file extension is not valid.")

let prepare_output_file name = open_out_bin name

let close_output_file output_chan = close_out output_chan

let output_of_input_file filename =
  if Filename.check_suffix filename ".re" then
    Filename.chop_suffix filename ".re" ^ ".ml"
  else if Filename.check_suffix filename ".rei" then
    Filename.chop_suffix filename ".rei" ^ ".mli"
  else if Filename.check_suffix filename ".ml" then
    Filename.chop_suffix filename ".ml" ^ ".re"
  else if Filename.check_suffix filename ".mli" then
    Filename.chop_suffix filename ".mli" ^ ".rei"
  else
    raise (Refmt_error "The file extension is not valid.")

let convert input_file =
  Reason_config.configure ~r:false;
  Location.input_name := input_file;
  let _ =
    Reason_pprint_ast.configure
      ~width:80
      ~assumeExplicitArity:true
      ~constructorLists:[]
  in
  let output_file = output_of_input_file input_file in
  let output_chan = prepare_output_file output_file in
  let eol = Eol_detect.get_eol_for_file input_file in
  let output_formatter = Eol_convert.get_formatter output_chan eol in
  let parse_output = parse input_file in
  print output_file parse_output output_formatter;
  (* Also closes all open boxes. *)
  Format.pp_print_flush output_formatter ();
  flush output_chan;
  close_output_file output_chan
