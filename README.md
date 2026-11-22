# testgui

A modern C++23 project.

## Building

```bash
cmake --preset dev
cmake --build --preset dev
ctest --preset dev
```

## Project Structure

- `include/` - Public headers
- `src/` - Implementation files
- `tests/` - Unit tests (Catch2)

## Configuration

Build options:
- `TESTGUI_BUILD_TESTS` - Build tests (default: ON)
- `TESTGUI_WARNINGS_AS_ERRORS` - Treat warnings as errors (default: OFF)
