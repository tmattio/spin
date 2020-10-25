# Contributing

## Setup your development environment

First, you will need to install [npm](https://npmjs.com) to install Javascript dependencies.

In `asset/`:

```
npm install
```

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
{%- endif %}

### Running the app

Building the project with `make build` will generate a file `main.js` that will inject our application in the `#root` element of `index.html`.

To run the application, we install `serve` as a dev dependencies. You can run a web server with the content of `asset/` with:

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

### Repository Structure

The following snippet describes {{ project_name }}'s repository structure.

```text
.
├── asset/
|   Static assets of the application.
│
├── bin/
|   Source for {{ project_slug }}'s compiled application. This links to the library defined in `lib/`.
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
├── esy.json
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
