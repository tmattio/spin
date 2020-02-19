# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added

- Before generating a template, Spin will check if the user has all the dependencies installed and exit gracefully if not. (by [@citizen428](https://github.com/citizen428))
- Add a `condition` field in the `postinstall` stanza for the templates.

### Changed

- Print a warning when the update of the official templates failed, but continue the execution.
- Do not update the official templates when running new with a local path or a git repository.
- Remove some runtime dependencies to reduce Spin's binary size.

### Fixed

- Trying to generate a file that already exists now raises an error instead of overwritting the file.
- Fix to output a proper message when no generator exist for the current project.
- Exit gracefully when failing to download a git repository or the initial templates for the first time. (by [@citizen428](https://github.com/citizen428))

## [0.4.8] - 2020-01-14

### Added

- Support user configuration file that stores general configuration such as the user's name, Github username, etc.
- Provide a `config` subcommand that can be used to change the user configuration.
- The generators can now print a message when the generation succeeds with the `message` stanza.

## [0.4.7] - 2020-01-13

### Added

- `post_install` stanza to run commands after installing a template now supports the `working_dir` stanza.
  The command will be executed in the given working directory.

### Changed

- Removed unused `starting_command` stanza.
- Removed unused `tutorial` stanza.

### Fixed

- Failure to parse a template file now prints an error with the file that cannot be parsed.

## [0.4.6] - 2020-01-11

### Changed

- Redirect stderr to dev null when calling git commands.

### Fixed

- Fix a wrong exit code when calling a generator that does not exist.
- Rename Homebrew formula to prevent duplication with existing `spin` formula.
- Fix installation from NPM using `yarn`

## ~~0.4.5 - 2020-01-11~~

This release has been unpublished.

## ~~0.4.4 - 2020-01-11~~

This release has been unpublished.

## ~~0.4.3 - 2020-01-11~~

This release has been unpublished.

## [0.4.2] - 2020-01-06

### Fixed

- Fix release artifacts on linux that was using darwin binaries.

## [0.4.1] - 2020-01-04

### Changed

- Use master branch of `spin-templates`.
- The template argument in `spin new` is not required. To use the minimal template, you can run `spin new native`.

### Fixed

- Use HTTPS instead of SSH to clone `spin-templates`.
- Remove duplicated git clone logs.

## [0.4.0] - 2020-01-02

### Added

- Create new projects from official templates with `spin new TEMPLATE`.
- Create new projects from git repositories with `spin new TEMPLATE`.
- Create new minimal projects with `spin new` when no argument is provided.
- Generate new modules in existing Spin projects with `spin gen [GENERATOR]`.
- List existing official templates with `spin ls`.
- Install with Homebrew.
- Install with a bash script.

[Unreleased]: https://github.com/tmattio/spin/compare/v0.4.8...HEAD
[0.4.8]: https://github.com/tmattio/spin/compare/v0.4.7...v0.4.8
[0.4.7]: https://github.com/tmattio/spin/compare/v0.4.6...v0.4.7
[0.4.6]: https://github.com/tmattio/spin/compare/v0.4.2...v0.4.6
[0.4.2]: https://github.com/tmattio/spin/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/tmattio/spin/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/tmattio/spin/releases/tag/v0.4.0
