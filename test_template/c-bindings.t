  $ export OPAMSKIPUPDATE=true
  $ export SPIN_CREATE_SWITCH=false
  $ export SPIN_PROJECT_NAME=demo
  $ export SPIN_AUTHOR_NAME=user
  $ export SPIN_TEST_FRAMEWORK=Alcotest
  $ spin new c-bindings _generated -d --ignore-config
  
  🏗️  Creating a new project from c-bindings in _generated
  Done!
  
  🎁  Installing packages globally. This might take a couple minutes.
  opam install -y dune-release ocamlformat utop ocaml-lsp-server
  [NOTE] Package ocaml-lsp-server is already installed (current version is 1.6.1).
  [NOTE] Package utop is already installed (current version is 2.7.0).
  [NOTE] Package ocamlformat is already installed (current version is 0.16.0).
  [NOTE] Package dune-release is already installed (current version is 1.4.0).
  opam install --deps-only --with-test --with-doc -y .
  [WARNING] Failed checks on demo package definition from source at file:///Users/tmattio/Workspace/private/spin/_build/.sandbox/fcbd2fc919b74b150ecbf054a804c023/default/test_template/_generated:
    warning 35: Missing field 'homepage'
    warning 36: Missing field 'bug-reports'
  Nothing to do.
  opam exec -- dune build --root .
            cc lib/demo_generated_stubs.o
  demo_generated_stubs.c:9:11: warning: format string is not a string literal (potentially insecure) [-Wformat-security]
     printf(x2);
            ^~
  demo_generated_stubs.c:9:11: note: treat the string as an argument to avoid this
     printf(x2);
            ^
            "%s", 
  1 warning generated.
  🎉  Success! Your project is ready at _generated
  
  Here are some example commands that you can run inside this directory:
  
    make deps
      Download runtime and development dependencies.
  
    make build
      Build the dependencies and the project.
  
    make test
      Starts the test runner.
  
  Happy hacking!

  $ cd _generated && make test > /dev/null 2>&1
