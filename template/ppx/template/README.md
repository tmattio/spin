# {{ project_name }}

{% if ci_cd == 'Github' -%}
[![Actions Status](https://github.com/{{ github_username }}/{{ project_slug }}/workflows/CI/badge.svg)](https://github.com/{{ github_username }}/{{ project_slug }}/actions)
{%- endif %}
[![NPM Version](https://badge.fury.io/js/%40{{ npm_username }}%2F{{ project_slug }}.svg)](https://badge.fury.io/js/%40{{ npm_username }}%2F{{ project_slug }})

{%- if project_description %}

{{ project_description }}
{%- endif %}

## Installation

### With `opam` on native projects

```bash
opam install {{ project_slug }}
```

### With `esy` on native projects

```bash
esy add @opam/{{ project_slug }}
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
