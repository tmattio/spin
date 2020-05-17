let pp_blue : string Fmt.t =
  let open Fmt in
  styled (`Fg `Blue) Fmt.string |> styled `Bold

let pp_yellow : string Fmt.t =
  let open Fmt in
  styled (`Fg `Yellow) Fmt.string |> styled `Bold

let pp_bright_green : string Fmt.t =
  let open Fmt in
  styled (`Fg (`Hi `Green)) Fmt.string |> styled `Bold
