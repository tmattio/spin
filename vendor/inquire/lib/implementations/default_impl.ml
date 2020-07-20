module M : Impl.M = struct
  open LTerm_text
  open LTerm_style

  let make_prompt message =
    eval
      [ B_fg green
      ; B_bold true
      ; S "? "
      ; B_fg white
      ; S (Printf.sprintf "%s " message)
      ; E_bold
      ; E_fg
      ]

  let make_error message =
    eval
      [ B_fg red
      ; B_bold true
      ; S "X "
      ; E_bold
      ; S (Printf.sprintf "%s" message)
      ; E_fg
      ]

  let make_select ~current options =
    List.mapi options ~f:(fun index option ->
        if current = index then
          [ B_fg green
          ; B_bold true
          ; S "> "
          ; E_bold
          ; E_fg
          ; B_fg white
          ; S (Printf.sprintf "%s\n" option)
          ; E_fg
          ]
        else
          [ S "  "; S (Printf.sprintf "%s\n" option) ])
    |> List.concat
    |> eval
end

include Factory.Make (M)
