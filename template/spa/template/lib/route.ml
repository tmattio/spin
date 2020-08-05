type t = Home

let from_url = function [] -> Some Home | _ -> None

let to_string = function Home -> "/"
