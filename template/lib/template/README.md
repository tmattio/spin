# {{ project_name }}

{%- if ci_cd == 'Github' %}

[![Actions Status](https://github.com/{{ github_username }}/{{ project_slug }}/workflows/CI/badge.svg)](https://github.com/{{ github_username }}/{{ project_slug }}/actions)
{%- endif %}

{%- if project_description %}

{{ project_description }}
{%- endif %}

## Installation

### Using Opam

```bash
opam install inquire
```

### Using Esy

```bash
esy add @opam/inquire
```

## Usage

### In OCaml

```ocaml
let () = {{ project_slug | modulify }}.Utils.greet "World"
```

### In Reason

```ocaml
{{ project_slug | modulify }}.Utils.greet("World");
```

## Contributing

Take a look at our [Contributing Guide](CONTRIBUTING.md).