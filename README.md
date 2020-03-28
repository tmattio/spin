<div align="center">
  <img src="docs/logo.png" als="Spin" />
</div>

<h4 align="center">Project scaffolding tool and set of templates for Reason and OCaml.</h4>

<p align="center">
  <a href="https://github.com/tmattio/spin/actions">
    <img src="https://github.com/tmattio/spin/workflows/Continuous%20Integration/badge.svg" alt="Build Status" />
  </a>
  <a href="https://badge.fury.io/js/%40tmattio%2Fspin">
    <img src="https://badge.fury.io/js/%40tmattio%2Fspin.svg" alt="npm version" />
  </a>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#installation">Installation</a> •
  <a href="#templates">Templates</a> •
  <a href="#usage">Usage</a> •
  <a href="#contributing">Contributing</a> •
  <a href="#roadmap">Roadmap</a>
</p>

<div align="center">
  <img src="https://raw.githubusercontent.com/tmattio/spin/master/docs/demo.svg?sanitize=true" alt="Demo">
</div>

## Features

🚀 Quickly start new projects that are ready for the real world.

❤️ Have a great developer experience when developing with Reason/OCaml.

🏄 Be as productive as Ruby-on-Rails or Elixir's Mix users.

🔌 Establish a convention for projects organizations to make it easy to get into new projects.

## Installation

### Using Homebrew (macOS)

```bash
brew install tmattio/tap/spin
```

### Using Opam

```bash
opam install spin
```

### Using npm

```bash
yarn global add @tmattio/spin
# Or
npm -g install @tmattio/spin
```

### Using a script

```bash
curl -fsSL https://github.com/tmattio/spin/raw/master/scripts/install.sh | bash
```

## Templates

You can generate a new project using a template with `spin new`. For instance:

```bash
spin new native my_app
```

Will create a new native application in the directory `./my_app/`

Anyone can create new Spin templates, but we provide [official templates](https://github.com/tmattio/spin-templates) for a lot of use cases. The official templates for each type of applications are listed below.

### Templates for native applications

- **[native](https://github.com/tmattio/spin-templates/tree/master/native)** - A native project containing the minimum viable configurations.
- **[cli](https://github.com/tmattio/spin-templates/tree/master/cli)** - Native command line interface.
- **[lib](https://github.com/tmattio/spin-templates/tree/master/lib)** - A library to be used in native or web applications.
- **[ppx](https://github.com/tmattio/spin-templates/tree/master/ppx)** - A PPX library to be used in native or web applications.

### Templates for Bucklescript applications

- **[bs-react](https://github.com/tmattio/spin-templates/tree/master/bs-react)** - React Single-Page-Application in Reason.

## Usage

### `spin new TEMPLATE [PATH] [--default] [--ignore-config]`

Create a new ReasonML/Ocaml project from a template.

`PATH` defaults to the current working directory.

When `--default` is passed, the user will not be prompted for configurations that have a default value.

When `--ignore-config` is passed, the configuration file will be ignored and the user will be prompted for all the configurations.

### `spin ls`

List the official Spin templates.

### `spin gen`

List the generators available for the current project.

### `spin gen GENERATOR`

Generate a new component in the current project.

### `spin config`

Prompt the user for values that can be saved in the configuration file.

If a value is present in the configuration file, it will not be prompted when generating a new project.

## Contributing

We would love your help improving Spin!

### Developing

You need Esy, you can install the latest version from [npm](https://npmjs.com):

```bash
yarn global add esy@latest
# Or
npm install -g esy@latest
```

> NOTE: Make sure `esy --version` returns at least `0.5.8` for this project to build.

Then run the `esy` command from this project root to install and build dependencies.

```bash
esy
```

Now you can run your editor within the environment (which also includes merlin):

```bash
esy $EDITOR
esy vim
```

Alternatively you can try [vim-reasonml](https://github.com/jordwalke/vim-reasonml)
which loads esy project environments automatically.

After you make some changes to source code, you can re-run project's build
again with the same simple `esy` command.

```bash
esy
```

This project uses [Dune](https://dune.build/) as a build system, and Pesy to generate Dune's configuration files. If you change the `buildDirs` configuration in `package.json`, you will have to regenerate the configuration files using:

```bash
esy pesy
```

### Running Binary

After building the project, you can run the main binary that is produced.

```bash
esy start
```

### Running Tests

You can test compiled executable (runs `scripts.tests` specified in `package.json`):

```bash
esy test
```

### Building documentation

Documentation for the libraries in the project can be generated with:

```bash
esy doc
open-cli $(esy doc-path)
```

This assumes you have a command like [open-cli](https://github.com/sindresorhus/open-cli) installed on your system.

> NOTE: On macOS, you can use the system command `open`, for instance `open $(esy doc-path)`

### Creating release builds

To release prebuilt binaries to all platforms, we use Github Actions to build each binary individually.

The binaries are then uploaded to a Github Release and NPM automatically.

To trigger the Release workflow, you need to push a git tag to the repository.
We provide a script that will bump the version of the project, tag the commit and push it to Github:

```bash
./scripts/release.sh
```

The script uses `npm version` to bump the project, so you can use the same argument.
For instance, to release a new patch version, you can run:

```bash
./scripts/release.sh patch
```

### Repository Structure

The following snippet describes Spin's repository structure.

```text
.
├── .github/
|   Contains Github specific files such as actions definitions and issue templates.
│
├── docs/
|   End-user documentation in Markdown format.
│
├── bin/
|   Source for Spin's binary. This links to the library defined in `lib/`.
│
├── lib/
|   Source for Spin's library. Contains Spin's core functionalities.
│
├── test/
|   Unit tests and integration tests for Spin.
│
├── test_runner/
|   Source for the test runner's binary.
|
├── dune-project
|   Dune file used to mark the root of the project and define project-wide parameters.
|   For the documentation of the syntax, see https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
│
├── LICENSE
│
├── package.json
|   Esy package definition.
|   To know more about creating Esy packages, see https://esy.sh/docs/en/configuration.html.
│
├── README.md
│
└── spin.opam
    Opam package definition.
    To know more about creating and publishing opam packages, see https://opam.ocaml.org/doc/Packaging.html.
```

## Roadmap

- Add more templates
  - **data-science** - Data Science workflow.
  - **desktop** - Native UI application using Revery.
  - **graphql-api** - HTTP server that serves a GraphQL API.
  - **rest-api** - HTTP server that serves a REST API.
  - **react-components** - React component library with Storybook.
  - **bs-bindings** - BuckleScript bindings to Javascript libraries.
- Support more CI/CD
  - GitLab
  - Azure
  - Google Build
  - Bitbucket Pipeline
- Create infrastructure of generated projects (i.e. generate terraform code)
- Write tutorials for the templates (e.g. Add user authentication for graphql-api)
