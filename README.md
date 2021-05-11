<p align="center">
    <img width="300" src="https://raw.githubusercontent.com/tmattio/spin/master/doc/logo.svg?sanitize=true" alt="Logo">
  	<br><br>
    Reason and OCaml project generator.
</p>


<p align="center">
  <a href="https://github.com/tmattio/spin/actions">
    <img src="https://github.com/tmattio/spin/workflows/CI/badge.svg" alt="Build Status" />
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
  <a href="#roadmap">Roadmap</a> •
  <a href="#contributing">Contributing</a> •
  <a href="#license">License</a> •
  <a href="#acknowledgements">Acknowledgements</a>
</p>

<div align="center">
  <img src="https://raw.githubusercontent.com/tmattio/spin/master/doc/demo.svg?sanitize=true" alt="Demo">
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

### Using a script

```bash
curl -fsSL https://github.com/tmattio/spin/raw/master/script/install.sh | bash
```

## Templates

You can generate a new project using a template with `spin new`. For instance:

```bash
spin new bin my_app
```

Will create a new binary application in the directory `./my_app/`

Anyone can create new Spin templates, but we provide official templates for a lot of use cases.

### Official templates

The official Spin templates templates are the following:

- **bin** - Native project containing a binary.
- **cli** - Command Line Interface releasable on Opam.
- **lib** - Library releasable on Opam.
- **ppx** - PPX library.
- **c-bindings** - Bindings to a C library.
- **js** - Js application with Js_of_ocaml.

If you'd like to add an official template, don't hesitate to open a PR!

### Other Reason/OCaml templates

Here are some non-official Spin templates that you can use:

- [**spin-rescript**](https://github.com/tmattio/spin-rescript) - Spin template for ReScript applicatoins
- [**spin-jsoo-react**](https://github.com/tmattio/spin-jsoo-react) - Spin template for React applicatoins with Js_of_ocaml
- [**spin-incr-dom**](https://github.com/tmattio/spin-incr-dom) - Single page application with Js_of_ocaml using Incr_dom

### Other non-OCaml templates

Although the focus of Spin is to offer a great project generator for the OCaml ecosystem, it can also be used to generate non-OCaml templates. Here are a few examples:

- [**spin-python-cli**](https://github.com/tmattio/spin-python-cli) - Spin template for Python CLIs

## Usage

For a detailed documentation of Spin's CLI, run `spin --help`, or refer to the [CLI documentation](https://github.com/tmattio/spin/tree/master/doc/cli.md).

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

## Roadmap

See our [development board](https://github.com/tmattio/spin/projects/1) for a list of selected features and issues.

## Contributing

We'd love your help improving Spin!

Take a look at our [Contributing Guide](CONTRIBUTING.md) to get started.

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for more information.

## Acknowledgements

Thanks to everyone who [contributed](https://github.com/tmattio/spin/graphs/contributors) to Spin!

Special thanks to [@wesoudshoorn](https://github.com/wesoudshoorn) for creating Spin's logo.
