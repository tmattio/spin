# Project Generator Configuration Syntax

This document outlines the syntax and structure of the project generator configuration file. The configuration file uses YAML format and includes several key sections for defining project parameters, file templates, and post-generation actions.

## Table of Contents

1. [Top-Level Structure](#top-level-structure)
2. [Config Section](#config-section)
   - [Input Fields](#input-fields)
   - [Select Fields](#select-fields)
   - [Validation](#validation)
3. [File Templates](#file-templates)
4. [Post Generation](#post-generation)
5. [Template Syntax](#template-syntax)

## Top-Level Structure

The configuration file starts with basic project information:

```yaml
name: demo
description: "Native project containing a binary"
```

- `name`: A short identifier for the project template.
- `description`: A brief description of what the template creates.

## Config Section

The `config` section defines the user inputs required to generate the project.

### Input Fields

Input fields prompt the user for text input.

```yaml
config:
  project_name:
    prompt: "Project name:"
    type: input

  project_description:
    prompt: "Description:"
    type: input
    default: "A short, but powerful statement about your project"
```

- `prompt`: The question presented to the user.
- `type`: Set to `input` for text input fields.
- `default` (optional): A default value if the user doesn't provide input.

### Select Fields

Select fields allow users to choose from predefined options.

```yaml
test_framework:
  prompt: "Which test framework do you prefer?"
  type: select
  options:
    - Alcotest
    - None
  default: Alcotest
```

- `type`: Set to `select` for option selection.
- `options`: A list of available choices.
- `default`: The default selection if the user doesn't choose.

### Validation

You can add validation rules to ensure user input meets certain criteria.

```yaml
project_slug:
  prompt: "Project slug:"
  type: input
  default: "{{ project_name | slugify }}"
  validate:
    - description: "The project slug must be lowercase and contain ASCII characters and '-' only."
      check: "{{ project_slug == project_slug | slugify }}"
```

- `validate`: A list of validation rules.
  - `description`: A human-readable description of the rule.
  - `check`: A template expression that should evaluate to true for valid input.

## File Templates

The `file_templates` section defines how files should be copied or generated in the new project.

```yaml
file_templates:
  - source: "test.alcotest/"
    destination: "test/"
    when: "{{ test_framework == 'None' }}"
  - source: ".github/"
    destination: ".github/"
    when: "{{ ci_cd == 'GitHub' }}"
```

- `source`: The source directory or file in the template.
- `destination`: Where the file(s) should be placed in the generated project.
- `when` (optional): A condition that determines whether this template should be used.

## Post Generation

The `post_generation` section defines actions to be taken after the project files are generated.

```yaml
post_generation:
  - message: "🎁  Building project. This might take a couple minutes."
  - run: 
      - "dune pkg lock"
      - "dune build"
  - message: |
      Project generated successfully! Here are some example commands to get you started:
      
      - Build the dependencies and the project:
        dune build
      
      - Start the test runner:
        dune test
      
      - Run the executable:
        dune exec bin/main.exe
```

- `message`: Displays a message to the user.
- `run`: Executes one or more shell commands.

## Template Syntax

The configuration uses a template syntax for dynamic values and conditions:

- `{{ variable }}`: Inserts the value of a variable.
- `{{ expression | filter }}`: Applies a filter to an expression.
- Filters:
  - `slugify`: Converts a string to a URL-friendly slug.
  - `last_char`: Returns the last character of a string.

Example:
```yaml
default: "{{ project_name | slugify }}"
```

This syntax allows for dynamic generation of values and conditional logic throughout the configuration.
