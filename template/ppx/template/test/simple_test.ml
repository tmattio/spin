{% if test_framework == 'Rely' -%}
open Test_framework

let test_simple_addition { expect; _ } =
    let result = [%{{ project_snake }} 5] in
    (expect.int result).toBe 10

let () =
    describe "Simple" @@ fun { test; _ } ->
    test "5 + 5 should equal 10" (test_simple_addition)
{%- else -%}
open Alcotest

let test_simple_addition () =
    let result = [%{{ project_snake }} 5] in
    check int "same value" 10 result

let suite = [ "5 + 5 should equal 10", `Quick, test_simple_addition ]
{% endif %}