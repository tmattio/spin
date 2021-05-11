{% if test_framework == 'Rely' -%}
(** Main entry point for our test runner.

    This simply calls the test framework CLI defined by Rely in the test
    library.

    We separate the test runner binary and the test library so that we can link
    all the modules in the library when compiling. This allows us to discover
    all the test automatically, instead of having to manually include them. *)

let () = {{ project_snake | capitalize }}_test.Test_framework.cli ()
{%- else -%}
(** Main entry point for our test runner.

    This aggregates all the test suites and call Alcotes to run them. When
    creating a new test suite, don't forget to add it here! *)

let () =
  Alcotest.run "{{ project_slug }}" [ "{{ project_snake | capitalize }}", {{ project_snake | capitalize }}_test.suite ]
{% endif -%}
