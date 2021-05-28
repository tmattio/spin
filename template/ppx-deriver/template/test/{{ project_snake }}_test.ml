open Alcotest

let test_simple_addition () =
    let result = [%{{ project_snake }} 5] in
    check int "same value" 10 result

let suite = [ "5 + 5 should equal 10", `Quick, test_simple_addition ]

let () =
  Alcotest.run "{{ project_slug }}" [ "{{ project_snake | capitalize }}", suite ]
