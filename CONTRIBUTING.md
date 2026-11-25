# Contributing to aw::template_cpp

Thank you for your interest in contributing to `template_cpp`! This document covers how to contribute and what to expect.

## Code of Conduct

Be respectful, inclusive, and constructive. Harassment or discrimination of any kind will not be tolerated.

## How to contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes following `AGENTS.md`
4. Commit using [Conventional Commits](https://www.conventionalcommits.org/)
5. Push to the branch (`git push origin feature/amazing-feature`) 
6. Open a Pull Request

## Development workflow

### Prerequisites

- CMake ≥ 3.21
- C++ compiler supporting C++23 (GCC ≥ 14, Clang ≥ 18, MSVC ≥ 19.40)
- Git

### Building

```sh
# Build the template (Debug)
cmake -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build --parallel

# Run tests
ctest --test-dir build -C Debug --output-on-failure
```

### Generating a project

```sh
make list
make init TYPE=static NAME=my-lib NS=aw::foo
make test
make selftest   # verify every template
```

See `README.md` and `AGENTS.md` ("Adding a template").

### Linting and formatting

```sh
# Format code
clang-format -i src/*.cpp include/*.hpp

# Lint with clang-tidy (requires a build first)
clang-tidy -p build src/*.cpp -- -std=c++20 -I include
```

### Testing

Tests use [Catch2 v3](https://github.com/catchorg/Catch2). Run them with:

```sh
ctest --test-dir build -C Debug --output-on-failure
```

The project CI uses the shared `pr-fast` reusable workflow for formatting, clang-tidy, and build/test of a generated static project. The `Selftest` workflow validates every generator template, including the MSVC path; `ShellCheck` validates the generator scripts. Sanitizer, coverage, and CI-container workflows remain project-specific. Releases run through the GitHub Actions `Release` workflow and shared catalog actions.

## Commit conventions

Use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` — new feature or archetype
- `fix:` — bug fix
- `docs:` — documentation changes
- `refactor:` — code restructuring without behavior changes
- `test:` — test additions or modifications
- `chore:` — maintenance, CI, tooling
- `ci:` — CI/CD workflow changes
- `changelog:` — CHANGELOG updates

## Pull requests

- All CI checks must pass
- At least one approving review
- Update `CHANGELOG.md` under `## [Unreleased]` with your changes
- Describe the motivation and scope of your changes

## Updating from the template

If you generated a project from this template and want to pull upstream updates:

```sh
git remote add template https://github.com/ai-warevo/template_cpp.git
git pull template main
```

The separation between template-owned (`examples/cmake/`) and project-owned code means updates should apply without conflicts.

## Questions?

Open an [issue](https://github.com/ai-warevo/template_cpp/issues).

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
