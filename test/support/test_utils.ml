open Spin

let decoder_error = Alcotest.of_pp Decoder.pp_error

let decoder a =
  let eq x y =
    match x, y with
    | Ok x, Ok y ->
      Alcotest.equal a x y
    | Error x, Error y ->
      Alcotest.equal decoder_error x y
    | _ ->
      false
  in
  Alcotest.testable
    (Fmt.Dump.result ~ok:(Alcotest.pp a) ~error:(Alcotest.pp decoder_error))
    eq

let get_tempdir prefix =
  let dirname =
    Printf.sprintf "%s-%s" prefix (Unix.time () |> Float.to_int |> Int.to_string)
  in
  Spin_std.Sys.mk_temp_dir dirname
