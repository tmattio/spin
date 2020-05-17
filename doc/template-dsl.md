# Template Syntax Reference

A spin file is used to define a template.

It is composed of the following stanzas.

## name

Defines the name of the template.

The template name must contain only alphanumeric characters, separated by `-` or `_`. 

```
(name <name>)
```

## description

Describes the template.

```
(description <description>)
```

## inherit

Inherits from a base template.

```
(inherit <source>
  <optional-fields>)
```

`<source>` can be one of:

- `(official <name>)` to inherit from the official template with the name `<name>`.
- `(git <repo>)` to inherit from a git repository wit the URI `<repo>`
- `(local <local-dir>)` to inherit from a local directory with the path `<local-dir>`

`<optional-fields>` are:

- `(skip <stanzas>)` to ignore stanzas in the base template. `<stanzas>` can be `configs`, `ignores`, `post_installs`, `example_commands`. 

Tip: if you want to ignore files from the base template, you can use the `ignore` stanza.

## config

Create a configuration for which the value will be accessible by the template engine.

```
(config <config-name>
  <optional-field>)
```

`<optional-fields>` are:

- `(input <input-fields>)` will prompt the user to input the value of the configuration
- `(select <select-fields>)` will prompt the user to select the value of the configuration
- `(confirm <confirm-fields>)` will prompt the user to confirm with 'yes' or 'no'.
- `(default <default-value>)` set a default value to the configuration. `<default-value>` can be a string, a configuration name, or a function call.
- `(enabled_if <cond>)` conditionally enables the configuration.

`input` `select` `confirm` are mutually exclusive.

`<input-fields>` are:

- `(prompt <message>)` define the message to display when prompting the user.

`<select-fields>` are:

- `(prompt <message>)` define the message to display when prompting the user.
- `(values <values>)` define the values to select from.

`<confirm-fields>` are:

- `(prompt <message>)` define the message to display when prompting the user.

## ignore

Ignore artefacts.


```
(ignore 
  (files <files>)
  <optional-fields>)
```

`<files>` is a list of path or glob expressions.

`<optional-fields>` are:

- `(enabled_if <cond>)` conditionally enables the action.

## post_gen

Perform actions after the template generation is complete.

```
(post_gen
  (action <action>)
  (actions <actions>)
  <optional-fields>)
```

- `(action <action>)` define an action to be performed. `<action>` can be one of `(run <command>)`, `(copy input output)`.
- `(actions <actions>)` define a list of actions to be performed. `<actions>` is a list of stanza with the same format as `<action>`.

`(action ...)` and `(actions ...)` are mutually exclusive.

`<optional-fields>` are:

- `(message <message>)` to display a message when the actions are performed.
- `(enabled_if <cond>)` conditionally enables the action.

## pre_gen

Perform actions before the template generation is started.

This supports the same fields as `post_gen`.

## example_commands

```
(example_commands
  (commands <commands>)
  <optional-fields>)

```

`<commands>` is a list of tuples composed of the command name and the description of the command. For instance `("make" "Build the project.")`

`<optional-fields>` are:

- `(enabled_if <cond>)` conditionally enables the action.
