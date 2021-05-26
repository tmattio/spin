let elt = Js_of_ocaml.Dom_html.getElementById_exn "root"

let () = {{ project_snake | capitalize }}.inject elt
