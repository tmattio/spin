# Unreleased

This release is a complete rewrite of Spin.

Since the beginning of the project, a lot of learnings have been made and this new version incorporates these learning to build a solid foundation for the future of Spin.

- Documentation of the CLI, template DSL and template engine.
- Better man page documentation
- Calling `spin` without a subcommand now displays a simpler usage documentation. The `man` page is available with `spin --help`
- The CLI now provides a verbose flag to increase the verbosity
- New template DSL
- Template extension
- Better error messages
- Improvements of the configuration prompts using Inquire
- Update native templates to follow best practices (e.g. name of libraries)
- Versionning of the templates
- Bucklescript templates now fallback to using `npm` when `yarn` is absent
- Windows is now supported
- The official templates are now embedded. No need to download a git repository, and the project generation works offline.

# 0.5.1 - 2020-03-17

## Added

- Add versionning for the official templates to ensure updates on the templates don't break old version of Spin.
- Sort `spin ls` result by name.

### Templates

- Rename react to bs-react. All the upcoming Bucklescript templates will be prefixed by bs-.
- Add a lib template that is releasable on Opam.
- Make the cli and ppx templates releasable on Opam.
- Add support for Alcotest as an alternative to Rely in the native templates.
- Add support for Opam as an alternative to Esy in the native templates.
- Stop using Pesy and the dune files manually in each sub-directories.
- Move the test_runner to a subdirectory support in test.
- Extract the Contributing section of the README to a CONTRIBUTING.md file.
- Add a CHANGES.md file that complies with dune-release requirements.
- Use dune-release in the release scripts.
- Remove homebrew Formula from the cli template that was a bad practice and didn’t allow users to update the generated projects.
- Enable Windows in CI/CD of generated projects

# 0.5.0 - 2020-03-07

## Added

- Before generating a template, Spin will check if the user has all the dependencies installed and exit gracefully if not. (by [@citizen428](https://github.com/citizen428))
- Add a `condition` field in the `postinstall` stanza for the templates.

## Changed

- Print a warning when the update of the official templates failed, but continue the execution.
- Do not update the official templates when running new with a local path or a git repository.
- Remove some runtime dependencies to reduce Spin's binary size.

## Fixed

- Trying to generate a file that already exists now raises an error instead of overwritting the file.
- Fix to output a proper message when no generator exist for the current project.
- Exit gracefully when failing to download a git repository or the initial templates for the first time. (by [@citizen428](https://github.com/citizen428))

# 0.4.8 - 2020-01-14

## Added

- Support user configuration file that stores general configuration such as the user's name, Github username, etc.
- Provide a `config` subcommand that can be used to change the user configuration.
- The generators can now print a message when the generation succeeds with the `message` stanza.

# 0.4.7 - 2020-01-13

## Added

- `post_install` stanza to run commands after installing a template now supports the `working_dir` stanza.
  The command will be executed in the given working directory.

## Changed

- Removed unused `starting_command` stanza.
- Removed unused `tutorial` stanza.

## Fixed

- Failure to parse a template file now prints an error with the file that cannot be parsed.

# 0.4.6 - 2020-01-11

## Changed

- Redirect stderr to dev null when calling git commands.

## Fixed

- Fix a wrong exit code when calling a generator that does not exist.
- Rename Homebrew formula to prevent duplication with existing `spin` formula.
- Fix installation from NPM using `yarn`

# ~~0.4.5 - 2020-01-11~~

This release has been unpublished.

# ~~0.4.4 - 2020-01-11~~

This release has been unpublished.

# ~~0.4.3 - 2020-01-11~~

This release has been unpublished.

# 0.4.2 - 2020-01-06

## Fixed

- Fix release artifacts on linux that was using darwin binaries.

# 0.4.1 - 2020-01-04

## Changed

- Use master branch of `spin-templates`.
- The template argument in `spin new` is not required. To use the minimal template, you can run `spin new native`.

## Fixed

- Use HTTPS instead of SSH to clone `spin-templates`.
- Remove duplicated git clone logs.

# 0.4.0 - 2020-01-02

## Added

- Create new projects from official templates with `spin new TEMPLATE`.
- Create new projects from git repositories with `spin new TEMPLATE`.
- Create new minimal projects with `spin new` when no argument is provided.
- Generate new modules in existing Spin projects with `spin gen [GENERATOR]`.
- List existing official templates with `spin ls`.
- Install with Homebrew.
- Install with a bash script.
