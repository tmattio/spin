include Stdlib.Hashtbl

let to_list t = to_seq t |> List.of_seq

let of_list l = of_seq (List.to_seq l)

let merge ~into:tab1 tab2 =
  fold (fun key elt () -> replace tab1 key elt) tab2 ()
