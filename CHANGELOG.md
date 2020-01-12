# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.5] - 2020-11-01

### Changed

- Redirect stderr to dev null when calling git commands.

### Fixed

- Fix a wrong exit code when calling a generator that does not exist.
- Rename Homebrew formula to prevent duplication with existing `spin` formula.
- Fix installation from NPM using `yarn`

## ~~0.4.4 - 2020-11-0~~

This release has been unpublished.

## ~~0.4.3 - 2020-11-01~~

This release has been unpublished.

## [0.4.2] - 2020-06-01

### Fixed

- Fix release artifacts on linux that was using darwin binaries.

## [0.4.1] - 2020-04-01

### Changed

- Use master branch of `spin-templates`.
- The template argument in `spin new` is not required. To use the minimal template, you can run `spin new native`.

### Fixed

- Use HTTPS instead of SSH to clone `spin-templates`.
- Remove duplicated git clone logs.

## [0.4.0] - 2020-02-01

### Added

- Create new projects from official templates with `spin new TEMPLATE`.
- Create new projects from git repositories with `spin new TEMPLATE`.
- Create new minimal projects with `spin new` when no argument is provided.
- Generate new modules in existing Spin projects with `spin gen [GENERATOR]`.
- List existing official templates with `spin ls`.
- Install with Homebrew.
- Install with a bash script.

[Unreleased]: https://github.com/tmattio/spin/compare/v0.4.5...HEAD
[0.4.5]: https://github.com/tmattio/spin/compare/v0.4.2...v0.4.5
[0.4.2]: https://github.com/tmattio/spin/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/tmattio/spin/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/tmattio/spin/releases/tag/v0.4.0
