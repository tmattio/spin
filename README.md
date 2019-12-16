# Spin

[![Actions Status](https://github.com/tmattio/spin/workflows/CI/CD%20Pipeline/badge.svg)](https://github.com/tmattio/spin/actions)

> Project scaffolding tool and set of templates for Reason and OCaml.

<div align="center">
  <img src="./docs/demo.svg" alt="Demo">
</div>

<br />

🚀 Quickly start new projects that are ready for the real world.

❤️ Have a great developer experience when developping with Reason/OCaml.

🏄 Be as productive as Ruby-on-Rails or Elixir's Mix users.

🔌 Establish a convention for projects organizations to make it easy to get into new projects.

## Why?

Reason and OCaml are by far my favourite languages! I've also worked on Elixir projects and saw with my own eyes how productive (and happy!) you can be with great toolings. I wish I had the best of both worlds: working with Reason and Ocaml and having a tooling worthy of Ruby-on-Rails.

On another hand, I spend a large part of my time working on deployment pipelines, databases, micro-service communication, etc. It's hard to see how this aligns with the value of the product I work on, especially when it seems that I am doing the same things over and over again. I wanted to reduce the time I spend on this kind of thing.

Finally, another characteristic of Elixir and RoR ecosystems that I envy: all the projects have the same structure and use the same conventions. This is very powerful, and they achieve this by having official real-world templates. I hope Reason and OCaml communities will come to this one day, but of course, the community adoption of Spin is outside of my control, all I can do is build great templates that people enjoy! 😁

## Installation

### Using Homebrew (macOS)

```bash
brew install https://raw.githubusercontent.com/tmattio/spin/master/scripts/install.rb
```

### Using Chocolatey (Windows)

```bash
choco install
```

### Using npm

```bash
yarn global add @tmattio/spin
# Or
npm -g install @tmattio/spin
```

### Using a script

```bash
curl -fsSL https://github.com/tmattio/spin/raw/master/dist/install.sh | bash
```

## Templates

Anyone can create new Spin templates, but we provide official templates for a lot of use cases.

You can see the list of official templates [here](https://github.com/tmattio/spin-templates) or by using `spin ls`.

You can generate a new project using a template with `spin new`. For instance:

```bash
spin new react my_app
```

Will create a new React application in the directory `./my_app/`

## Usage

### `spin new TEMPLATE [PATH]`

Create a new ReasonML/Ocaml project from a template.

### `spin ls`

List the official Spin templates.

### `spin gen`

List the generators available for the current project.

### `spin gen GENERATOR`

Generate a new component in the current project.

## Contributing

We would love your help improving Spin!

### Developing

```bash
npm install -g esy
git clone git@github.com:tmattio/spin.git
esy install
esy build
```

### Running Binary

After building the project, you can run the main binary that is produced.

```bash
esy x spin.exe
```

### Running Tests

```bash
# Runs the "test" command in `package.json`.
esy test
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
├── executable/
|   Source for the spin executable's interface, its subcommands and the man page content.
│
├── library/
|   Source for Spin's library. Contains most of spin's internal functionnalities.
│
├── test/
|   Unit tests and integration tests for Spin.
│
├── dune
|   Dune file used to define project-wide parameters.
│
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
  - **bs-bindings** - Bucklescript bindings to Javascript libraries.
- Create infrastructure of generated projects (i.e. generate terraform code)
- Write tutorials for the templates (e.g. Add user authentication for graphql-api)
