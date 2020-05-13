```sh
$ export SPIN_PROJECT_NAME=demo && \
> export SPIN_SYNTAX=OCaml && \
> export SPIN_PACKAGE_MANAGER=Opam && \
> export SPIN_TEST_FRAMEWORK=Alcotest && \
> spin new bin _generated -d

🏗️  Creating a new project from bin in _generated
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
$ cd _generated && make test
...
```
