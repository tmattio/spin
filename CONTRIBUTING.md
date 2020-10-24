# Contributing

## Setup your development environment

You need Opam, you can install it by following [Opam's documentation](https://opam.ocaml.org/doc/Install.html).

With Opam installed, you can install the dependencies with:

```bash
make deps
```

Then, build the project with:

```bash
make build
```

### Running Binary

After building the project, you can run the main binary that is produced.


```bash
make start
```

### Running Tests

You can run the test compiled executable:


```bash
make test
```

### Building documentation

Documentation for the libraries in the project can be generated with:


```bash
make doc
open-cli $(make doc-path)
```

This assumes you have a command like [open-cli](https://github.com/sindresorhus/open-cli) installed on your system.

> NOTE: On macOS, you can use the system command `open`, for instance `open $(make doc-path)`

### Releasing

To release prebuilt binaries to all platforms, we use Github Actions to build each binary individually.

The binaries are then uploaded to a Github Release and NPM automatically.

To trigger the Release workflow, you need to push a git tag to the repository.
We provide a script that will bump the version of the project, tag the commit and push it to Github:

```bash
./script/release.sh
```

The script will release the current project version on Opam, update the documentation and push a new tag on Github.

### Releasing

To create a release and publish it on Opam, first update the `CHANGES.md` file with the last changes and the version that you want to release.
The, you can run the script `script/release.sh`. The script will perform the following actions:

- Create a tag with the version found in `spin.opam`, and push it to your repository.
- Create the distribution archive.
- Publish the distribution archive to a Github Release.
- Submit a PR on Opam's repository.

When the release is published on Github, the CI/CD will trigger the `Release` workflow which will perform the following actions

- Compile binaries for all supported platforms.
- Create an NPM release containing the pre-built binaries.
- Publish the NPM release to the registry.

### Repository Structure

The following snippet describes Spin's repository structure.

```text
.
├── .github/
|   Contains Github specific files such as actions definitions and issue templates.
│
├── bin/
|   Source for Spin's binary. This links to the library defined in `lib/`.
│
├── lib/
|   Source for Spin's library. Contains Spin's core functionnalities.
│
├── test/
|   Unit tests and integration tests for Spin.
│
├── dune-project
|   Dune file used to mark the root of the project and define project-wide parameters.
|   For the documentation of the syntax, see https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
│
├── LICENSE
│
├── Makefile
|   Make file containing common development command.
│
├── README.md
│
└── spin.opam
    Opam package definition.
    To know more about creating and publishing opam packages, see https://opam.ocaml.org/doc/Packaging.html.
```
