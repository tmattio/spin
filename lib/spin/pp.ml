let pp_blue : Format.formatter -> string -> unit =
  let open Fmt in
  styled (`Fg `Blue) Fmt.string |> styled `Bold

let pp_yellow : Format.formatter -> string -> unit =
  let open Fmt in
  styled (`Fg `Yellow) Fmt.string |> styled `Bold

let pp_bright_green : Format.formatter -> string -> unit =
  let open Fmt in
  styled (`Fg (`Hi `Green)) Fmt.string |> styled `Bold
