type t = Home

let from_url = function [] | [ "" ] -> Some Home | _ -> None

type t' = string

let home = "/"
