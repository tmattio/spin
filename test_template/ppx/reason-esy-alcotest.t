  $ export SPIN_PROJECT_NAME=demo
  $ export SPIN_USERNAME=user
  $ export SPIN_SYNTAX=Reason
  $ export SPIN_PACKAGE_MANAGER=Esy
  $ export SPIN_TEST_FRAMEWORK=Alcotest
  $ spin new ppx _generated -d --ignore-config

  🏗️  Creating a new project from ppx in _generated
  Done!

  🎁  Installing packages. This might take a couple minutes.
  Done!

  🎉  Success! Your project is ready at _generated

  Here are some example commands that you can run inside this directory:

    make dev
      Download runtime and development dependencies.

    make build
      Build the dependencies and the project.

    make test
      Starts the test runner.

  Happy hacking!
  $ cd _generated && make test > /dev/null
  ...