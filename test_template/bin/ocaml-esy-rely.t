  $ export OPAMSKIPUPDATE=true
  $ export SPIN_CREATE_SWITCH=false
  $ export SPIN_PROJECT_NAME=demo
  $ export SPIN_USERNAME=user
  $ export SPIN_SYNTAX=OCaml
  $ export SPIN_PACKAGE_MANAGER=Esy
  $ export SPIN_TEST_FRAMEWORK=Rely
  $ spin new bin _generated -d --ignore-config

  🏗️  Creating a new project from bin in _generated
  Done!

  🎁  Installing packages globally. This might take a couple minutes.
  Done!

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
