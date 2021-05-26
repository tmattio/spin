open Js_of_ocaml

let inject elt =
  let greeting = "Hello World" in
  let content = elt##.innerHTML##concat (Js.string greeting) in
  elt##.innerHTML := content
