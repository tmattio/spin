include Spin_std.Spawn

let default_fd () =
  if Config.verbose () then
    None
  else
    Some
      (if Sys.win32 then
         Unix.openfile "nul" [ Unix.O_RDWR ] 0o666
      else
        Unix.openfile "/dev/null" [ Unix.O_RDWR ] 0o666)

let exec ?env ?cwd ?stdin ?stdout ?stderr prog argv =
  let stdout = match stdout with Some x -> Some x | None -> default_fd () in
  let stderr = match stderr with Some x -> Some x | None -> default_fd () in
  exec ?env ?cwd ?stdin ?stdout ?stderr prog argv
