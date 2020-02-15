/** Main entry point for our test runner.

    This aggregates all the test suites and calls Alcotest to run them. When
    creating a new test suite, don't forget to add it here! */
Alcotest.run(
  "spin",
  [
    ("Integration - Command gen", Cmd_gen_test.suite),
    ("Integration - Command new", Cmd_new_test.suite),
    ("Integration - Smoke", Smoke_test.suite),
    ("Jg_wrapper", Jg_wrapper_test.suite),
    ("Template", Template_test.suite),
    ("Utils", Utils_test.suite),
    ("VCS", Vcs_test.suite),
  ],
);