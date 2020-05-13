open Alcotest
open Spin

let decoder_error = of_pp Decoder.pp_error

let decoder a =
  let eq x y =
    match x, y with
    | Ok x, Ok y ->
      equal a x y
    | Error x, Error y ->
      equal decoder_error x y
    | _ ->
      false
  in
  testable (Fmt.Dump.result ~ok:(pp a) ~error:(pp decoder_error)) eq

let get_tempdir prefix =
  Printf.sprintf "%s-%s" prefix (Unix.time () |> Float.to_int |> Int.to_string)
  |> Caml.Filename.concat (Caml.Filename.get_temp_dir_name ())
