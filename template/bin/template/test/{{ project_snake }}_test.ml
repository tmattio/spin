open Alcotest

let test_hello_with_name name () =
  let greeting = {{ project_snake | capitalize }}.greet name in
  let expected = "Hello " ^ name ^ "!" in
  check string "same string" greeting expected

let suite =
  [ "can greet Tom", `Quick, test_hello_with_name "Tom"
  ; "can greet John", `Quick, test_hello_with_name "John"
  ]

let () =
  Alcotest.run "{{ project_slug }}" [ "{{ project_snake | capitalize }}", suite ]
