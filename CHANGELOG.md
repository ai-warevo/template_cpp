# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!--
Maintainer notes (see AGENTS.md, "Changelog and releases"):
- Add every user-visible change under `## [Unreleased]` in the same commit that makes it.
- Categories: Breaking, Added, Changed, Deprecated, Removed, Fixed, Security. Omit empty ones.
- The GitHub Actions Release workflow uses shared catalog actions to prepare releases.
-->

## [Unreleased]

## [0.6.0] - 2026-11-24

### Added

- gui
- gui
- add cmake modules and base CMakeLists to _common for reuse
- add CHANGELOG.md to _common template
- add common root files to _common template
- add CI templates (.github/workflows and release.yml)

### Changed

- fixik
- fixik
- wayland go away
- eliminate remaining // comments in test files and inline comments
- clean up C++ comments and update AGENTS.md
- ci :3
- update GitHub secrets path in instructions
- clarify certificate export and FetchContent cache clearing
- add certificate setup instructions directly in CodeSign.cmake
- add comprehensive Windows code signing setup guide
- ci
- ai
- ai
- ai
- remove CMakeLists.txt and duplicate CMakePresets.json from root
- remove duplicated cmake modules from _common (use FetchContent)
- ai slop
- move CI/CD templates to _common for DRY
- add known issues and solutions from gitsync project
- parametrize container image in all workflows
- use reusable-coverage-badge workflow
- split coverage job into generate + deploy for container safety
- remove duplicate workflow_dispatch trigger
- add workflow_dispatch to weekly-deep for manual testing

### Fixed

- gui gg
- ci
- fix
- fixes
- wayland=off
- fixes
- fixes
- ci
- ai
- selftest to auto-answer prompts and filter internal templates
- remove tracked CMakeUserPresets.json and add shared CMakePresets.json root
- tools
- ignore code signing errors if certificate not found
- use named arguments for aw_find_winsdk_tool()
- use include(Windows/WindowsSDK) instead of CMAKE_CURRENT_LIST_DIR
- use CMAKE_CURRENT_LIST_DIR for WindowsSDK include
- correct include path and cmake_parse_arguments in CodeSign.cmake
- ai slop
- remove trailing slashes from gcovr_source_filter for consistency
- remove env.CI_CONTAINER_IMAGE from container.image
- enable coverage badge updates for scheduled/manual runs

### Removed

- remove exit 0 - let signing fail if cert not available

## [0.5.8] - 2026-11-22

### Changed

- Merge branch 'main' of https://github.com/ai-warevo/template_cpp

### Fixed

- remove glob patterns from clang-tidy exclude

## [0.5.7] - 2026-11-22

### Changed

- ci <3

## [0.5.6] - 2026-11-22

### Changed

- centralize shared CMake project, target, test helpers in AWProject facade
- fix
- Merge pull request #9 from ai-vibeqodez/fix/msvc-compiler-detection
- Merge pull request #8 from ai-vibeqodez/fix/msvc-fetchcontent-url
- Merge branch 'main' of github.com:ai-warevo/template_cpp

### Fixed

- configure MSVC warning flags after compiler detection
- detect MSVC compiler before project() using CMAKE_CXX_COMPILER path
- detect MSVC compiler before project() using CMAKE_CXX_COMPILER path
- use template_cpp (underscore) in FetchContent and comments
- fix

## [0.5.5] - 2026-11-21

### Changed

- ci

### Fixed

- fix

## [0.5.4] - 2026-11-21

### Changed

- ci
- Merge branch 'main' of github.com:ai-warevo/template_cpp
- Merge pull request #7 from ai-vibeqodez/fix/pr-weekly-ci-project
- ci
- Merge pull request #6 from ai-warevo/loktionov129-patch-2
- Update README.md
- Merge branch 'main' of github.com:ai-warevo/template_cpp
- ci

### Fixed

- add setup_command to pr-test and weekly-deep workflows

## [0.5.3] - 2026-11-21

### Changed

- Update README.md
- centralize C++23 compiler & consumer integration modules
- fix
- fix
- ci

### Fixed

- cmamke C++23

## [0.5.2] - 2026-11-20

### Changed

- Merge pull request #4 from ai-vibeqodez/fix/reusable-release-split
- reuse release

### Fixed

- use shared release workflow
- restore generator release workflow
- fix
- Merge branch 'main' of github.com:ai-warevo/template_cpp
- ik

## [0.5.1] - 2026-11-20

### Changed

- Route PR fast checks through the shared ai-warevo reusable workflow.
- Use catalog actions for release automation and remove local release/changelog updater scripts.
- Stop copying release tooling into generated projects and document contributor guidance in `AGENTS.md`.

## [0.5.0] - 2026-11-18

### Added

- add script updater with auto-sync and pre-flight checks


## [0.4.2] - 2026-11-18

### Fixed

- fix duplicate heading and empty tag list handling

## [0.4.1] - 2026-11-18

### Fixed

- scripts
- quote CMake flags with spaces in coverage job extra_args
- re-run apt-get update before installing forky packages
- remove clang-format/clang-tidy, CI actions install them
- use deepseek-harness base, add libunwind+libclang-rt, remove docker-in-d
- use debian:trixie, remove forky, add all toolchains
- switch to debian:trixie, remove forky entirely
- restore forky repo matching Dockerfile.fix
- remove forky pinning, install gcc-15 directly
- add "dev" preset to CMakePresets.json
- fix IS_POSIX detection in Makefile
- disable SC2016 in selftest.sh printf
- resolve SC2016 in selftest.sh printf

### Changed

- add MSVC support to all CI/CD workflows
- add container-based CI workflow
- use Debian-based CI image with gcc-15 from forky and clang-18
- synchronize project configs and add CMakeUserPresets.json.example

## [0.4.0] - 2026-11-17

### Added

- `make init … OUT=<dir>` (`AW_OUT`): generate into another directory. `examples/` is now a managed path.
- `static` template: `examples/` with a sample, `FILE_SET HEADERS`, install rules, the options `<NAME>_BUILD_TESTS`, `_BUILD_EXAMPLES`, `_INSTALL` and `_WARNINGS_AS_ERRORS`, and CMake 3.23 as the minimum.
- `aw_test_target(SOURCES …)` accepts several test sources (`TESTS_SOURCE` still works).
- `aw_install_library(DEPENDENCIES …)` writes `find_dependency()` calls into the package config; `NS` may be the full alias (`aw::tpl`).
- `clang18-libcxx` preset (`clang++-18 -stdlib=libc++`).

### Changed

- `static` template: the CMake alias is now `@@NS@@` (e.g. `aw::foo`) instead of `@@NS@@::@@NAME@@`; the tests, install and example targets follow. Tests/examples/install default to `OFF` when used as a subproject.

### Fixed

- `static` template: the include guard `#endif` now comes after the closing namespace.

## [0.3.0] - 2026-11-17

### Added

- read project VERSION from file instead of hardcoding
- `make init TYPE=<type> [NAME=] [NS=] [TESTS=0] [DRY=1]`: pure-Bash project generator (`templates/scaffold.sh`) with `cli`, `static` and `dynamic` templates, `@@KEY@@` placeholders, type aliases and name inference.
- `make list`, `make eject`, `make selftest`, and shared `CMakePresets.json`.

### Fixed

- move AW_WARNINGS setup after project() to fix MSVC build
- use basename for log file paths and add debug info
- print cmake output on build failure for debugging
- remove CMAKE_BUILD_TYPE from presets to silence MSVC warning
- use uname to detect Windows and skip CMAKE_BUILD_TYPE for MSVC
- remove CMAKE_BUILD_TYPE from preset to silence MSVC warning

### Changed

- use reusable cmake/ modules and scaffold.sh shared-file copy
- Replaced the old archetype-based `make init ARCHETYPE=... PROJECT=...` with the generator above.

## [0.2.0] - 2026-11-17

### Added

- `make init TYPE=<type> [NAME=] [NS=] [TESTS=0] [DRY=1]`: pure-Bash project generator (`templates/scaffold.sh`) with `cli`, `static` and `dynamic` templates, `@@KEY@@` placeholders, type aliases and name inference.
- `make list`, `make eject`, `make selftest`, and shared `CMakePresets.json`.

### Changed

- Replaced the old archetype-based `make init ARCHETYPE=... PROJECT=...` with the generator above.

## [0.1.0] - 2026-11-14

### Added

- First release of the `template_cpp` repository.

[Unreleased]: https://github.com/ai-warevo/template_cpp/compare/v0.6.0...HEAD
[0.6.0]: https://github.com/ai-warevo/template_cpp/compare/v0.5.8...v0.6.0
[0.5.8]: https://github.com/ai-warevo/template_cpp/compare/v0.5.7...v0.5.8
[0.5.7]: https://github.com/ai-warevo/template_cpp/compare/v0.5.6...v0.5.7
[0.5.6]: https://github.com/ai-warevo/template_cpp/compare/v0.5.5...v0.5.6
[0.5.5]: https://github.com/ai-warevo/template_cpp/compare/v0.5.4...v0.5.5
[0.5.4]: https://github.com/ai-warevo/template_cpp/compare/v0.5.3...v0.5.4
[0.5.3]: https://github.com/ai-warevo/template_cpp/compare/v0.5.2...v0.5.3
[0.5.2]: https://github.com/ai-warevo/template_cpp/compare/v0.5.1...v0.5.2
[0.5.1]: https://github.com/ai-warevo/template_cpp/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/ai-warevo/template_cpp/compare/v0.4.2...v0.5.0
[0.4.2]: https://github.com/ai-warevo/template_cpp/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/ai-warevo/template_cpp/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/ai-warevo/template_cpp/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/ai-warevo/template_cpp/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/ai-warevo/template_cpp/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/ai-warevo/template_cpp/releases/tag/v0.1.0
