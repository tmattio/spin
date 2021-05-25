include Stdlib.Result

let both a b =
  match a with
  | Error e ->
    Error e
  | Ok a ->
    (match b with Error e -> Error e | Ok b -> Ok (a, b))

module Syntax = struct
  let ( >>= ) t f = bind t f

  let ( >>| ) t f = map f t

  let ( let* ) = ( >>= )

  let ( let+ ) = ( >>| )

  let ( and+ ) = both
end

open Syntax

module List = struct
  let map f t =
    let rec loop acc = function
      | [] ->
        Ok (List.rev acc)
      | x :: xs ->
        f x >>= fun x -> loop (x :: acc) xs
    in
    loop [] t

  let all =
    let rec loop acc = function
      | [] ->
        Ok (List.rev acc)
      | t :: l ->
        t >>= fun x -> loop (x :: acc) l
    in
    fun l -> loop [] l

  let concat_map =
    let rec loop f acc = function
      | [] ->
        Ok (List.rev acc)
      | x :: l ->
        f x >>= fun y -> loop f (List.rev_append y acc) l
    in
    fun l f -> loop f [] l

  let rec iter f t =
    match t with [] -> Ok () | x :: xs -> f x >>= fun () -> iter f xs

  let rec fold_left f init t =
    match t with
    | [] ->
      Ok init
    | x :: xs ->
      f init x >>= fun init -> fold_left f init xs

  let rec iter_left f t =
    match t with [] -> Ok () | x :: xs -> f x >>= fun () -> iter_left f xs

  let filter_map t f =
    fold_left
      (fun acc x -> f x >>| function None -> acc | Some y -> y :: acc)
      []
      t
    >>| List.rev
end
