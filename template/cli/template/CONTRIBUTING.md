# Contributing

## Setup your development environment

You need Opam, you can install it by following [Opam's documentation](https://opam.ocaml.org/doc/Install.html).

With Opam installed, you can install the dependencies with:

With Opam installed, you can install the dependencies in a new local switch with:

```bash
make switch
```

Or globally, with:

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
make servedoc
```

### Releasing

To create a release and publish it on Opam, first update the `CHANGES.md` file with the last changes and the version that you want to release.
The, you can run the script `script/release.sh`. The script will perform the following actions:

- Create a tag with the version found in `{{ project_slug }}.opam`, and push it to your repository.
- Create the distribution archive.
- Publish the distribution archive to a GitHub Release.
- Submit a PR on Opam's repository.

When the release is published on GitHub, the CI/CD will trigger the `Release` workflow which will compile binaries for all supported platforms and add them to the GitHub Release as assets.

### Repository Structure

The following snippet describes {{ project_name }}'s repository structure.

```text
.
├── .github/
|   Contains GitHub specific files such as actions definitions and issue templates.
│
├── bin/
|   Source for {{ project_name }}'s binary. This links to the library defined in `lib/`.
│
├── lib/
|   Source for {{ project_name }}'s library. Contains {{ project_name }}'s core functionnalities.
│
├── test/
|   Unit tests and integration tests for {{ project_name }}.
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
└── {{ project_slug }}.opam
    Opam package definition.
    To know more about creating and publishing opam packages, see https://opam.ocaml.org/doc/Packaging.html.
```
