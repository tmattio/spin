# {{ project_name }}

{% if ci_cd == 'Github' -%}
[![Actions Status](https://github.com/{{ github_username }}/{{ project_slug }}/workflows/CI/badge.svg)](https://github.com/{{ github_username }}/{{ project_slug }}/actions)
{%- endif %}

{%- if project_description %}

{{ project_description }}
{%- endif %}

## Features

- Available on all major platform (Windows, Linux and Windows)

## Installation

### Using Opam

```bash
opam install {{ project_slug }}
```

### Using a script

```bash
curl -fsSL https://github.com/{{ github_username }}/{{ project_slug }}/raw/master/script/install.sh | bash
```

## Usage

### `{{ project_slug }} hello NAME`

Greets the name given in argument.

## Contributing

Take a look at our [Contributing Guide](CONTRIBUTING.md).
