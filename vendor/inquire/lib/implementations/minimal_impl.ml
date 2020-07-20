module M : Impl.M = struct
  open LTerm_text
  open LTerm_style

  let make_prompt message = eval [ S "? "; S (Printf.sprintf "%s" message) ]

  let make_error message = eval [ S "X "; S (Printf.sprintf "%s" message) ]

  let make_select ~current options =
    List.mapi options ~f:(fun index option ->
        if current = index then
          [ S "> "; S (Printf.sprintf "%s\n" option) ]
        else
          [ S "  "; S (Printf.sprintf "%s\n" option) ])
    |> List.concat
    |> eval
end

include Factory.Make (M)
