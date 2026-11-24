# ⚡ aw::template_cpp

> **A minimal C++23 project generator, like `dotnet new`.**
> Pick a template, run one command, start coding.

[![C++23](https://img.shields.io/badge/C++-%2300599C.svg?logo=c%2B%2B&logoColor=white)](https://cppreference.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Coverage](https://raw.githubusercontent.com/ai-warevo/template_cpp/refs/heads/badges/coverage.svg)](https://ai-warevo.github.io/template_cpp)
<br />
[![Selftest](https://github.com/ai-warevo/template_cpp/actions/workflows/selftest.yml/badge.svg)](https://github.com/ai-warevo/template_cpp/actions/workflows/selftest.yml)
[![ShellCheck](https://github.com/ai-warevo/template_cpp/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/ai-warevo/template_cpp/actions/workflows/shellcheck.yml)
<br />
[![PR Build](https://github.com/ai-warevo/template_cpp/actions/workflows/pr-build.yml/badge.svg)](https://github.com/ai-warevo/template_cpp/actions/workflows/pr-build.yml)
[![PR Test](https://github.com/ai-warevo/template_cpp/actions/workflows/pr-test.yml/badge.svg)](https://github.com/ai-warevo/template_cpp/actions/workflows/pr-test.yml)
<br />
[![Weekly Deep](https://github.com/ai-warevo/template_cpp/actions/workflows/weekly-deep.yml/badge.svg)](https://github.com/ai-warevo/template_cpp/actions/workflows/weekly-deep.yml)
[![Release](https://github.com/ai-warevo/template_cpp/actions/workflows/release.yml/badge.svg)](https://github.com/ai-warevo/template_cpp/actions/workflows/release.yml)

The repository root stays clean. `CMakeLists.txt`, `src/`, `include/`, `tests/` and (for some templates) `examples/` appear only after `make init`.
The generator is pure Bash (3.2+), so it runs on Linux, macOS and Windows Git Bash. It needs no Python.
 
## CI/CD

`pr-fast.yml` calls the shared `ai-warevo/.github` reusable workflow for formatting, build, clang-tidy, and test checks. The selftest, Windows, ShellCheck, sanitizer/coverage, and CI-container checks remain project-specific because they validate this repository's generator and templates. Releases are run from the GitHub Actions **Release** workflow, which uses shared changelog and release actions; no project release scripts are required.

## Quick start

```sh
git clone https://github.com/ai-warevo/template_cpp.git my-project
cd my-project

make list                                   # show templates
make init TYPE=static NAME=my-lib NS=aw::foo
make test                                   # configure + build + run tests
make eject                                  # optional: remove the generator (templates/)
```

Git for Windows does not ship `make`. Call the script directly instead:
`bash templates/scaffold.sh init static --name my-lib --ns aw::foo`.

## Templates

| `TYPE`    | Aliases               | Produces                                                         |
|-----------|-----------------------|------------------------------------------------------------------|
| `cli`     | `console`, `exe`, `app` | Executable: a small core library plus `main.cpp`               |
| `static`  | `lib`, `library`      | Static library with a public header                              |
| `dynamic` | `dll`, `so`, `shared` | Shared library with generated export macros (`GenerateExportHeader`) |
| `gui`     | `ui`, `window`, `desktop` | Cross-platform GUI app + embeddable overlay (GLFW + Dear ImGui docking + event bus) |

All templates are C++23 (`cxx_std_23`), with `-Wall -Wextra -Wpedantic` (or `/W4` on MSVC) and Catch2 v3 tests.

## `make init`

```sh
make init TYPE=<type> [NAME=<name>] [NS=<namespace>] [OUT=<dir>] [TESTS=0] [DRY=1]
```

| Option  | Default               | Meaning                                                                                              |
|---------|-----------------------|------------------------------------------------------------------------------------------------------|
| `TYPE`  | required              | Template name or alias.                                                                              |
| `NAME`  | current directory name | `[a-z][a-z0-9_-]*`. Not a C++ keyword and no `__`.                                                  |
| `NS`    | `aw::unnamed`         | C++ namespace, `::`-separated identifiers (e.g. `aw::foo::bar`).                                     |
| `OUT`   | repository root       | Directory to generate into (must exist). `make init … --out DIR` does **not** work: make eats the flag. |
| `TESTS` | `1`                   | `TESTS=0` skips `tests/` and the Catch2 `FetchContent` setup.                                        |
| `DRY`   | `0`                   | `DRY=1` prints the files that would be generated and writes nothing.                                 |

Re-running `make init` **overwrites** `CMakeLists.txt`, `src/`, `include/` and `tests/` without asking, and prints a warning that lists them.
Rendering happens in a staging directory first, so a validation error never leaves a half-generated project.

After a successful init you get a `make eject` hint. `make eject` removes `templates/` (the generator, its templates and its selftest).
The shared files stay in the repository root.

### Namespace example

`make init TYPE=static NAME=foo NS=aw::foo` generates:

```
CMakeLists.txt                    # add_library(foo ...) + alias aw::foo, FILE_SET HEADERS, options, install rules
include/aw/foo/foo.hpp            # namespace aw::foo { ... }
src/foo.cpp
examples/CMakeLists.txt
examples/01_basic.cpp
tests/CMakeLists.txt
tests/foo_tests.cpp
```

The `static` template's CMake alias is the **namespace itself** (`aw::foo`), so use a namespace that ends in the project name.
It also provides these options (`<NAME>` is the upper-cased project name, e.g. `FOO`):

| Option                    | Default                          | Meaning                                              |
|---------------------------|----------------------------------|------------------------------------------------------|
| `<NAME>_BUILD_TESTS`      | `ON` when top level, else `OFF`  | Build `tests/` (Catch2 via FetchContent)             |
| `<NAME>_BUILD_EXAMPLES`   | `ON` when top level, else `OFF`  | Build `examples/`                                    |
| `<NAME>_INSTALL`          | `ON` when top level, else `OFF`  | Install rules + package config (`find_package(foo)`) |
| `<NAME>_WARNINGS_AS_ERRORS` | `OFF`                          | Adds `-Wshadow -Wconversion -Werror` (`/WX`) to the library and examples |

Public dependencies are declared in two places: `target_link_libraries(... PUBLIC ...)` and `DEPENDENCIES` of `aw_install_library()`,
which writes one `find_dependency()` per entry into the package config.

The reusable `cmake/AWProject.cmake` facade provides `aw_project_prepare()` / `aw_project_setup()`,
`aw_add_library()`, `aw_add_executable()`, `aw_setup_tests()`, and the existing install/test helpers.
Consumer projects can keep source and header manifests local while sharing compiler warnings, C++23 settings,
test discovery, include paths, and optional subdirectory handling.

## Project targets

```sh
make build            # cmake --preset dev (Debug), or BUILD_TYPE=Release
make test
make lint             # clang-tidy (needs a build)
make format           # clang-format
make clean
```

These use [`CMakePresets.json`](CMakePresets.json) (`dev` = Debug, `release`, `clang18-libcxx` = Debug with `clang++-18 -stdlib=libc++`). You can also call `cmake --preset dev` yourself.

### Releases

Run GitHub Actions **Release** workflow to promote the prepared `## [Unreleased]` section, choose the next SemVer version from `CHANGELOG.md`, update `VERSION`, create a `vX.Y.Z` tag, and publish a GitHub Release. The workflow uses the shared catalog release workflow and intentionally does not build the repository root because this generator has no root `CMakeLists.txt`; generated projects are validated by the CI workflows. The optional `version` input accepts an explicit `X.Y.Z` override; leave it as `auto` to derive the version from changelog categories. For a release prepared outside Actions, push its `vX.Y.Z` tag to publish the GitHub Release.

## Layout

```
Makefile              thin wrapper: help, list, init, selftest, eject, build/test/lint/format/clean
CMakePresets.json     shared presets (dev, release, clang18-libcxx)
VERSION               project version
CHANGELOG.md          user-visible changes
CONTRIBUTING.md       how to contribute
.clang-format .clang-tidy .editorconfig .gitignore .gitattributes
cmake/                shared CMake modules (ProjectConfig, AWProject, Tests, CoreLibrary, Library/, Windows/)
templates/
  scaffold.sh         the generator: list | init | eject
  selftest.sh         generates, builds and tests every template
  <type>/
    template.conf     DESCRIPTION="..." and ALIASES="..."
    files/            mirrors the project root; rendered with @@KEY@@ placeholders
```

## Placeholders

`@@KEY@@` is replaced in file **contents** and in file and directory **names**.
Any `@@KEY@@` left unresolved fails the run and names the file and line.

| Key               | `NAME=my-lib NS=aw::foo`  | Typical use                                |
|-------------------|---------------------------|--------------------------------------------|
| `@@NAME@@`        | `my-lib`                  | CMake project and target names             |
| `@@NAME_ID@@`     | `my_lib`                  | File stems and C++ identifiers             |
| `@@NAME_UPPER@@`  | `MY_LIB`                  | Macros                                     |
| `@@NS@@`          | `aw::foo`                 | Qualified names, CMake alias namespace     |
| `@@NS_OPEN@@`     | `namespace aw::foo {`     | Opens the namespace                        |
| `@@NS_CLOSE@@`    | `} // namespace aw::foo`  | Closes the namespace                       |
| `@@NS_PATH@@`     | `aw/foo`                  | Include directory layout                   |
| `@@NS_UPPER@@`    | `AW_FOO`                  | Macro prefixes                             |
| `@@MACRO_PREFIX@@`| `AW_FOO_MY_LIB`           | Export macro, e.g. `AW_FOO_MY_LIB_API`     |
| `@@TYPE@@`        | `static`                  | Informational                              |

## Adding a template

1. `cp -r templates/static templates/<new-type>`.
2. Edit `template.conf` (`DESCRIPTION`, `ALIASES`) and the files under `files/`.
3. Run `make selftest`.

The script needs no edits, because templates are auto-discovered. See [`AGENTS.md`](AGENTS.md) for the rules.

## Verifying

`make selftest` generates each template into a temporary directory, then configures, builds and runs `ctest`.
It also checks validation errors, aliases, `--dry-run`, re-init, `--no-tests`, name inference and eject.
It needs `cmake`, a C++23 compiler, and network access for Catch2 (unless Catch2 v3 is installed).

## License

MIT. See [`LICENSE`](LICENSE).
