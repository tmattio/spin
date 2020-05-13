{% if test_framework == 'Rely' -%}
open Test_framework
open {{ project_slug | modulify }}

(** Test suite for the Utils module. *)

let test_hello_with_name name { expect } =
  let greeting = Utils.greet name in
  let expected = "Hello " ^ name ^ "!" in
  (expect.string greeting).toEqual expected

let () =
  describe "Utils" @@ fun { test; _ } ->
  test "can greet Tom" (test_hello_with_name "Tom");
  test "can greet John" (test_hello_with_name "John")
{%- else -%}
open Alcotest
open {{ project_slug | modulify }}

(** Test suite for the Utils module. *)

let test_hello_with_name name () =
  let greeting = Utils.greet name in
  let expected = "Hello " ^ name ^ "!" in
  check string "same string" greeting expected

let suite =
  [ "can greet Tom", `Quick, test_hello_with_name "Tom"
  ; "can greet John", `Quick, test_hello_with_name "John"
  ]
{% endif %}