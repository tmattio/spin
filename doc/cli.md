# Command Line Interface

`spin` must be used with a subcommand.

The available subcommands are:

- [`config`](#config) - Update the current user's configuration
- [`gen`](#gen) - Generate a new component in the current project
- [`ls`](#ls) - List the official templates
- [`new`](#new) - Generate a new project from a template

These options are available to all subcommands:

- `--help[=FMT] (default=auto)`

    Show this help in format FMT. The value FMT must be one of `auto',
    `pager', `groff' or `plain'. With `auto', the format is `pager` or
    `plain' whenever the TERM env var is `dumb' or undefined.
    
- `-q, --quiet`

    Be quiet. Takes over -v and --verbosity.

- `-v, --verbose`

    Increase verbosity. Repeatable, but more than twice does not bring
    more.

- `--verbosity=LEVEL (absent=warning or SPIN_VERBOSITY env)`

    Be more or less verbose. LEVEL must be one of `quiet', `error',
    `warning', `info' or `debug'. Takes over -v.

- `--version`

    Show version information.

## `config`

```
spin config [OPTIONS]...
```

### Description

The `config` command prompts the user for global configuration values
that will be saved in `$SPIN_CONFIG_DIR/config`
(`~/.config/spin/config` by default).

Unless `--ignore-config` is used, the configuration values stored in
`$SPIN_CONFIG_DIR/config` will be used when creating new projects (with
`new`) and the user will not be prompted for configuration that have 
been saved.

### Options

- `-C PATH`

    Run as if spin was started in `PATH` instead of the current directory.

## `ls`

```
spin ls [OPTION]...
```

### Description

`ls` will list the available official template with their description.

### Options

- `-C PATH`

    Run as if spin was started in PATH instead of the current
    directory.

## `new`

```
spin new [OPTION]... TEMPLATE [PATH]
```

### Description

`new` generates projects from templates. The template can be either an official template, local directory or a remote git repository.

You can use `ls` to list the official templates.

### Arguments

- `PATH`

    The path where the project will be generated. If absent, the
    project will be generated in the current working directory.

- `TEMPLATE (required)`

    The template to use. The template can be the name of an official
    template, a local directory or a remote git repository.

### Options

- `-C PATH`

    Run as if spin was started in PATH instead of the current
    directory.

- `-d, --default`

    Use default values without prompting when the configuration has a
    default value.

- `--ignore-config`

    Prompt for values regardless of whether they are in the user's
    configuration file.
