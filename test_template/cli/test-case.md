# OCaml - Opam - Alcotest

```sh
$ export SPIN_PROJECT_NAME=demo SPIN_USERNAME=user SPIN_SYNTAX=OCaml SPIN_PACKAGE_MANAGER=Opam SPIN_TEST_FRAMEWORK=Alcotest && \
> spin new cli _generated -d --ignore-config

🏗️  Creating a new project from cli in _generated
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
$ export SPIN_CMD_NAME=test && \
> spin gen cmd -C _generated --ignore-config

🏗️  Running the generator cmd
Done!

You need to add `Cmd_test.cmd` to your list of commands in bin/main.ml
$ test -f _generated/bin/commands/cmd_test.ml
$ rm -rf _generated
```

# Reason - Opam - Alcotest

```sh
$ export SPIN_PROJECT_NAME=demo SPIN_USERNAME=user SPIN_SYNTAX=Reason SPIN_PACKAGE_MANAGER=Opam SPIN_TEST_FRAMEWORK=Alcotest && \
> spin new cli _generated -d --ignore-config

🏗️  Creating a new project from cli in _generated
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
$ export SPIN_CMD_NAME=test && \
> spin gen cmd -C _generated --ignore-config

🏗️  Running the generator cmd
Done!

You need to add `Cmd_test.cmd` to your list of commands in bin/main.re
$ test -f _generated/bin/commands/cmd_test.re
$ rm -rf _generated
```

# OCaml - Esy - Alcotest

```sh
$ export SPIN_PROJECT_NAME=demo SPIN_USERNAME=user SPIN_SYNTAX=OCaml SPIN_PACKAGE_MANAGER=Esy SPIN_TEST_FRAMEWORK=Alcotest && \
> spin new cli _generated -d --ignore-config

🏗️  Creating a new project from cli in _generated
Done!

🎁  Installing packages. This might take a couple minutes.
Done!

🎉  Success! Your project is ready at _generated

Here are some example commands that you can run inside this directory:

  esy install
    Download and lock the dependencies.

  esy build
    Build the dependencies and the project.

  esy test
    Starts the test runner.

Happy hacking!
$ cd _generated && esy test
...
$ export SPIN_CMD_NAME=test && \
> spin gen cmd -C _generated --ignore-config

🏗️  Running the generator cmd
Done!

You need to add `Cmd_test.cmd` to your list of commands in bin/main.ml
$ test -f _generated/bin/commands/cmd_test.ml
$ rm -rf _generated
```

# Reason - Esy - Alcotest

```sh
$ export SPIN_PROJECT_NAME=demo SPIN_USERNAME=user SPIN_SYNTAX=Reason SPIN_PACKAGE_MANAGER=Esy SPIN_TEST_FRAMEWORK=Alcotest && \
> spin new cli _generated -d --ignore-config

🏗️  Creating a new project from cli in _generated
Done!

🎁  Installing packages. This might take a couple minutes.
Done!

🎉  Success! Your project is ready at _generated

Here are some example commands that you can run inside this directory:

  esy install
    Download and lock the dependencies.

  esy build
    Build the dependencies and the project.

  esy test
    Starts the test runner.

Happy hacking!
$ cd _generated && esy test
...
$ export SPIN_CMD_NAME=test && \
> spin gen cmd -C _generated --ignore-config

🏗️  Running the generator cmd
Done!

You need to add `Cmd_test.cmd` to your list of commands in bin/main.re
$ test -f _generated/bin/commands/cmd_test.re
$ rm -rf _generated
```

# OCaml - Opam - Rely

```sh
$ export SPIN_PROJECT_NAME=demo SPIN_USERNAME=user SPIN_SYNTAX=OCaml SPIN_PACKAGE_MANAGER=Opam SPIN_TEST_FRAMEWORK=Rely && \
> spin new cli _generated -d --ignore-config

🏗️  Creating a new project from cli in _generated
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
$ export SPIN_CMD_NAME=test && \
> spin gen cmd -C _generated --ignore-config

🏗️  Running the generator cmd
Done!

You need to add `Cmd_test.cmd` to your list of commands in bin/main.ml
$ test -f _generated/bin/commands/cmd_test.ml
$ rm -rf _generated
```

# Reason - Opam - Rely

```sh
$ export SPIN_PROJECT_NAME=demo SPIN_USERNAME=user SPIN_SYNTAX=Reason SPIN_PACKAGE_MANAGER=Opam SPIN_TEST_FRAMEWORK=Rely && \
> spin new cli _generated -d --ignore-config

🏗️  Creating a new project from cli in _generated
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
$ export SPIN_CMD_NAME=test && \
> spin gen cmd -C _generated --ignore-config

🏗️  Running the generator cmd
Done!

You need to add `Cmd_test.cmd` to your list of commands in bin/main.re
$ test -f _generated/bin/commands/cmd_test.re
$ rm -rf _generated
```

# OCaml - Esy - Rely

```sh
$ export SPIN_PROJECT_NAME=demo SPIN_USERNAME=user SPIN_SYNTAX=OCaml SPIN_PACKAGE_MANAGER=Esy SPIN_TEST_FRAMEWORK=Rely && \
> spin new cli _generated -d --ignore-config

🏗️  Creating a new project from cli in _generated
Done!

🎁  Installing packages. This might take a couple minutes.
Done!

🎉  Success! Your project is ready at _generated

Here are some example commands that you can run inside this directory:

  esy install
    Download and lock the dependencies.

  esy build
    Build the dependencies and the project.

  esy test
    Starts the test runner.

Happy hacking!
$ cd _generated && esy test
...
$ export SPIN_CMD_NAME=test && \
> spin gen cmd -C _generated --ignore-config

🏗️  Running the generator cmd
Done!

You need to add `Cmd_test.cmd` to your list of commands in bin/main.ml
$ test -f _generated/bin/commands/cmd_test.ml
$ rm -rf _generated
```

# Reason - Esy - Rely

```sh
$ export SPIN_PROJECT_NAME=demo SPIN_USERNAME=user SPIN_SYNTAX=Reason SPIN_PACKAGE_MANAGER=Esy SPIN_TEST_FRAMEWORK=Rely && \
> spin new cli _generated -d --ignore-config

🏗️  Creating a new project from cli in _generated
Done!

🎁  Installing packages. This might take a couple minutes.
Done!

🎉  Success! Your project is ready at _generated

Here are some example commands that you can run inside this directory:

  esy install
    Download and lock the dependencies.

  esy build
    Build the dependencies and the project.

  esy test
    Starts the test runner.

Happy hacking!
$ cd _generated && esy test
...
$ export SPIN_CMD_NAME=test && \
> spin gen cmd -C _generated --ignore-config

🏗️  Running the generator cmd
Done!

You need to add `Cmd_test.cmd` to your list of commands in bin/main.re
$ test -f _generated/bin/commands/cmd_test.re
$ rm -rf _generated
```
