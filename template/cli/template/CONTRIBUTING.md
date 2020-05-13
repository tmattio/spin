# Contributing

## Setup your development environment

{% if package_manager == 'Esy' -%}
You need Esy, you can install the latest version from [npm](https://npmjs.com):

```bash
yarn global add esy@latest
# Or
npm install -g esy@latest
```

Then run the `esy` command from this project root to install and build depenencies.

```bash
esy
```

This project uses [Dune](https://dune.build/) as a build system, if you add a dependency in your `package.json` file, don't forget to add it to your `dune` and `dune-project` files too.
{%- else -%}
You need Opam, you can install it by following [Opam's documentation](https://opam.ocaml.org/doc/Install.html).

With Opam installed, you can install the dependencies with:

```bash
make dev
```

Then, build the project with:

```bash
make build
```
{%- endif %}

### Running Binary

After building the project, you can run the main binary that is produced.

{% if package_manager == 'Esy' -%}
```bash
esy start
```
{%- else %}
```bash
make start
```
{%- endif %}

### Running Tests

You can run the test compiled executable:

{% if package_manager == 'Esy' -%}

```bash
esy test
```
{%- else %}
```bash
make test
```
{%- endif %}

### Building documentation

Documentation for the libraries in the project can be generated with:

{% if package_manager == 'Esy' -%}
```bash
esy doc
open-cli $(esy doc-path)
```

This assumes you have a command like [open-cli](https://github.com/sindresorhus/open-cli) installed on your system.

> NOTE: On macOS, you can use the system command `open`, for instance `open $(esy doc-path)`
{%- else %}
```bash
make doc
open-cli $(make doc-path)
```

This assumes you have a command like [open-cli](https://github.com/sindresorhus/open-cli) installed on your system.

> NOTE: On macOS, you can use the system command `open`, for instance `open $(make doc-path)`
{%- endif %}

### Releasing

To create a release and publish it on Opam, first update the `CHANGES.md` file with the last changes and the version that you want to release.
The, you can run the script `script/release.sh`. The script will perform the following actions:

- Create a tag with the version found in `{{ project_slug }}.opam`, and push it to your repository.
- Create the distribution archive.
- Publish the distribution archive to a Github Release.
- Submit a PR on Opam's repository.

When the release is published on Github, the CI/CD will trigger the `Release` workflow which will perform the following actions

- Compile binaries for all supported platforms.
- Create an NPM release containing the pre-built binaries.
- Publish the NPM release to the registry.

### Repository Structure

The following snippet describes {{ project_name }}'s repository structure.

```text
.
├── .github/
|   Contains Github specific files such as actions definitions and issue templates.
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
{%- if package_manager == 'Esy' %}
├── package.json
|   Esy package definition.
|   To know more about creating Esy packages, see https://esy.sh/docs/en/configuration.html.
{%- else %}
├── Makefile
|   Make file containing common development command.
{%- endif %}
│
├── README.md
│
└── {{ project_slug }}.opam
    Opam package definition.
    To know more about creating and publishing opam packages, see https://opam.ocaml.org/doc/Packaging.html.
```
