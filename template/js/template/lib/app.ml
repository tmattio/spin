open Js_of_ocaml

let inject elt =
  let greeting = Utils.greet "World" in
  let content = elt##.innerHTML##concat (Js.string greeting) in
  elt##.innerHTML := content
