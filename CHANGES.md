# Unreleased

## Added

- Added a `parse_binaries` stanza that can be `true` to force Spin to parse binary files
- Added a `raw_files` stanza that takes a list of file or glob expressions to instruct Spin to copy files instead of parsing them

## Changed

- The `spa` template has been removed from the official templates and now lives at https://github.com/tmattio/spin-incr-dom
- Spin does not parse binary files by default anymore, they are simply copied to the destination folder
- Use `test` stanza for unit tests now that Alcotest prints colors by default
- Remove unused flags defined in the root's `dune` file

## Fixes

- The project generation will now fail before the configurations prompt if the output directory is not empty
- By default, Spin now creates a local switch for the generated projects. This can be changed with `spin config`, or by setting the env variable `SPIN_CREATE_SWITCH=false`

# 0.7.0

## Added

- Added a new `spa` template to generate Single-Page-Application with Js_of_ocaml
- Dune's `--root` argument in templates' Makefiles to better compose generated projects
- The templates CI/CD is now caching Opam dependencies to improve build time
- The templates are now installing locked dependencies by default during CI/CD
- The Makefile of the templates include a small inlined python script to open the documentation with the default browser with the command `servedoc`

## Changed

- Removed the `bs-react` template from the official templates. The template now lives in [tmattio/spin-rescript](https://github.com/tmattio/spin-rescript).
- Removed dependency on Reason and use the generated project's Reason to convert `.ml` files to `.re`.

## Fixed

- Fixed NPM release by vendoring a Chamomille-free version of Inquire
- Remove wrong release flags from all templates

# 0.6.0 - 2020-05-17

This release is a complete rewrite of Spin.

Since the beginning of the project, a lot of learnings have been made and this new version incorporates these learning to build a solid foundation for the future of Spin.

## Added

- New template DSL
- Template inheritance with the `(inherit ...)` stanza
- Documentation of the CLI and template DSL.
- The CLI now provides a verbose flag to increase the verbosity
- The git templates are now cached

## Changed

- Calling `spin` without a subcommand now displays a simpler usage documentation. The `man` page is available with `spin --help`
- Better man page documentation
- Better error messages
- Improvements of the configuration prompts using Inquire
- Update native templates to follow best practices (e.g. name of libraries)
- The official templates are now embedded. No need to download a git repository, and the project generation works offline.

## Fixed

- Bucklescript templates now fallback to using `npm` when `yarn` is absent

# 0.5.1 - 2020-03-17

## Added

- Add versionning for the official templates to ensure updates on the templates don't break old version of Spin.
- Sort `spin ls` result by name.

## Templates

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
