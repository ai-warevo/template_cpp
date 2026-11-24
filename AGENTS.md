# AGENTS.md

Guidance for working on this project. Read `README.md` for the user-facing API; this file covers implementation rules.

## Project architecture

This repository is a `dotnet new`-style C++23 project generator. The root stays clean: `CMakeLists.txt`, `src/`, `include/`, and `tests/` exist only in generated projects. Template sources live under `templates/<type>/files/`.

- `Makefile` is a thin wrapper for the generator and generated-project build targets.
- `templates/scaffold.sh` owns generator behavior (`list`, `init`, `eject`) and must remain compatible with Bash 3.2+.
- `templates/selftest.sh` generates each template, builds it, runs tests, and checks generator invariants.
- `templates/<type>/template.conf` is sourced in a subshell; only `DESCRIPTION` and space-separated `ALIASES` are read.
- `templates/<type>/files/` mirrors a generated project. Its top-level entries must remain in `MANAGED` in `scaffold.sh`.
- `SHARED_FILES` in `scaffold.sh` lists root files copied as-is into generated projects. Do not add release or CI implementation scripts there.
- There is no `templates/_common/`; templates are self-contained by design.

## Generator invariants

- Keep `scaffold.sh` compatible with Bash 3.2 (macOS) and Git Bash: no associative arrays, `mapfile`, `${value^^}`, or `sed -i`.
- Render into a staging directory, then move into place so validation failures do not leave partial output.
- Re-running `init` replaces the managed paths unconditionally and warns first; this is specified behavior.
- `eject` removes only `templates/`.
- Template and shell source files are LF-only.
- Template placeholders are replaced in file contents and paths. Add new keys consistently to the generator and document them in `README.md`.

## CI/CD

GitHub Actions owns CI and releases. Reuse `ai-warevo/.github` composite actions and reusable workflows via `@main` wherever they fit the project. Keep project-specific workflows only for checks that exercise this generator or its generated templates and cannot be represented by catalog workflows.

- `pr-fast.yml` uses the catalog reusable PR workflow for generated-project formatting, build, clang-tidy, and tests.
- Selftest, Windows, ShellCheck, and CI-container image checks are generator-specific.
- Release and changelog promotion run from GitHub Actions using catalog composite actions; do not add local release/changelog scripts or mirror their logic in Make targets.
- When adding or changing workflows, retain the project-specific generation and release behavior and update the CI/CD section in `README.md`.

## Changelog and releases

Keep `CHANGELOG.md` in Keep a Changelog format. Add user-visible changes under `## [Unreleased]` in the same commit, categorized as `Breaking`, `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, or `Security` (omit empty categories). The manual release workflow promotes the prepared changelog; alternatively, pushing a `vX.Y.Z` tag publishes an existing changelog release. Release logic is not run locally.

## Adding a template

1. Copy the closest existing template to `templates/<type>`.
2. Define `DESCRIPTION` and non-conflicting `ALIASES` in `template.conf`.
3. Keep the template self-contained; avoid cross-template includes.
4. Put tests in `files/tests/`, with a local `CMakeLists.txt` and Catch2 v3 via FetchContent. The root `CMakeLists.txt` may only guard `tests/CMakeLists.txt` for `TESTS=0`.
5. Use the documented placeholders such as `@@NS_OPEN@@`, `@@NS_CLOSE@@`, `@@NS_PATH@@`, and `@@NAME_ID@@`.
6. Run `make selftest` and update the template table in `README.md`.

### GUI Template Requirements

The `gui` template has special architecture requirements:

- **Three-layer separation:** Core (pure C++23, zero `imgui.h`), UI (ImGui rendering), and deliverables (app + overlay)
- **Headless unit tests:** State/config/registry tests must run without GLFW/OpenGL initialization
- **Platform-specific overlays:** Separate `overlay_win32.cpp` and `overlay_posix.cpp` with conditional compilation
- **GUI-specific Docker image:** Use `Dockerfile.gui` (inherits from base, adds X11/OpenGL/GLFW/ImGui)
- **CI support:** Xvfb for headless Linux testing; Windows native build

### Dependency Caching

**Local-first resolution strategy:**
1. `FETCHCONTENT_SOURCE_DIR_<NAME>` (explicit local override)
2. `/opt/deps` (Docker cache, pre-populated stable deps)
3. `$ENV{AW_DEPS_DIR}` (user-defined cache directory)
4. `find_package(... QUIET)` (system install)
5. `FetchContent` (network fallback)

**Docker pre-population:**
- Base image: Catch2, spdlog, nlohmann/json (stable external deps)
- GUI image: GLFW, Dear ImGui docking branch, X11/Mesa headers
- **Do NOT** bake `aw::tpl` or `aw::tobus` — actively developed internal libs, always fetch fresh

**CMake helper:** Use `aw_fetch_dependency(NAME ... GIT_REPOSITORY ... GIT_TAG ...)` in `AWProject.cmake`.

## C++ Comments

- **Explain "Why" only:** Delete comments that merely narrate code (e.g., `// increment i`). Assume readers know C++. Keep only comments explaining intent, business logic, edge cases, or architectural decisions.
- **Prefer block syntax:** Use `/* ... */` for multi-line or standalone comments; reserve `//` for rare, ultra-short inline notes (e.g., `0xFF38BDF8; /* Cyan accent. */`) or mandatory tool directives (`// NOLINT`).
- **API documentation:** Use Doxygen (`/// ...` or `/** ... */`) for public function, class, and type headers.

