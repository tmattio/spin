let find_list_index ~f l =
  let rec aux i = function
    | [] ->
      None
    | el :: _ when f el ->
      Some i
    | _ :: rest ->
      aux (i + 1) rest
  in
  aux 0 l

let index_of_default ?default l =
  Option.bind default (fun default ->
      find_list_index ~f:(String.equal default) l)
  |> Option.value ~default:0

let index_of_default_opt ?default l =
  Option.bind default (fun default ->
      find_list_index ~f:(String.equal default) l)
