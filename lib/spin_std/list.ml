include Stdlib.List

let index f t =
  let rec aux acc = function
    | [] ->
      raise Not_found
    | el :: rest ->
      if f el then
        acc
      else
        aux (acc + 1) rest
  in
  aux 0 t
