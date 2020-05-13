let () =
  let filepath =
    try Caml.Sys.argv.(1) with
    | _ ->
      Caml.print_endline (Printf.sprintf "Usage: %s FILEPATH" Caml.Sys.argv.(0));
      Caml.exit 1
  in
  Spin_refmt.convert filepath
