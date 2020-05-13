# {{ project_name }}

{% if ci_cd == 'Github' -%}
[![Actions Status](https://github.com/{{ github_username }}/{{ project_slug }}/workflows/CI/badge.svg)](https://github.com/{{ github_username }}/{{ project_slug }}/actions)
{%- endif %}
[![NPM Version](https://badge.fury.io/js/%40{{ npm_username }}%2F{{ project_slug }}.svg)](https://badge.fury.io/js/%40{{ npm_username }}%2F{{ project_slug }})

{%- if project_description %}

{{ project_description }}
{%- endif %}

## Features

- Deploy prebuilt binaries to be consumed from Bucklescript projects

## Installation

### With `opam` on native projects

```bash
opam install {{ project_slug }}
```

### With `esy` on native projects

```bash
esy add @opam/{{ project_slug }}
```

### With `npm` on Bucklescript projects

The recommended way to use PPX libraries in Bucklescript projects is to use `esy`.

Create an `esy.json` file with the content:

```json
{
  "name": "test_bs",
  "version": "0.0.0",
  "dependencies": {
    "@opam/{{ project_slug }}": "*",
    "ocaml": "~4.6.1000"
  }
}
```

And add the PPX in your `bsconfig.json` file:

```json
{
  "ppx-flags": [
    "ppx-flags": ["esy x {{ project_slug }}"]
  ]
}
```

However, if using `esy` bothers you, we also provide a NPM package with prebuilt binaries.

```bash
yarn global add @{{ npm_username }}/{{ project_slug }}
# Or
npm -g install @{{ npm_username }}/{{ project_slug }}
```

And add the PPX in your `bsconfig.json` file:

```json
{
  "ppx-flags": [
    "ppx-flags": ["@{{ npm_username }}/{{ project_slug }}"]
  ]
}
```

## Usage

`{{ project_snake }}` implements a ppx that transforms the `[%{{ project_snake }}]` extension into an expression that adds 5 to the integer passed in parameter.

The code:

```ocaml
[%{{ project_snake }} 5]
```

Will transform to something like:

```ocaml
5 + 5
```

## Contributing

Take a look at our [Contributing Guide](CONTRIBUTING.md).
