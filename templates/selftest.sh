#!/usr/bin/env bash
# shellcheck disable=SC2016
# selftest.sh — generate every template into a temp dir, then configure, build and test it.
#   selftest.sh [TYPE...]     (default: all templates)
set -eu

TPL_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(dirname "$TPL_DIR")
SCAFFOLD="bash $TPL_DIR/scaffold.sh"
# Don't let a developer's AW_* environment leak into the checks.
unset AW_TYPE AW_NAME AW_NS AW_TESTS AW_DRY

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'ok   %s\n' "$*"; }
section() { printf '\n== %s ==\n' "$*"; }

command -v cmake >/dev/null 2>&1 || { echo "selftest: cmake not found" >&2; exit 1; }

WORK=$(mktemp -d "${TMPDIR:-/tmp}/aw-selftest.XXXXXX")
trap 'rm -rf "$WORK"' EXIT

# Fresh project dir with the shared root presets, like a real checkout.
newproj() { # DIRNAME
    mkdir -p "$WORK/$1"
    cp "$ROOT_DIR/CMakePresets.json" "$WORK/$1/"
    printf '%s' "$WORK/$1"
}

# Same as newproj but also copies VERSION (needed for CMake VERSION file read).
newproj_ver() { # DIRNAME
    mkdir -p "$WORK/$1"
    cp "$ROOT_DIR/CMakePresets.json" "$WORK/$1/"
    cp "$ROOT_DIR/VERSION" "$WORK/$1/"
    printf '%s' "$WORK/$1"
}
expect_fail() { # DESCRIPTION CMD...
    local d=$1; shift
    if "$@" >/dev/null 2>&1; then fail "$d (command unexpectedly succeeded)"; fi
    pass "$d"
}
build_and_test() { # DIR TESTS(1|0)
    # Windows CMake can't read MSYS paths such as /tmp/...; cygpath -m (Git Bash) fixes that.
    local d=$1
    if command -v cygpath >/dev/null 2>&1; then d=$(cygpath -m "$d"); fi
    # CMAKE_BUILD_TYPE is only needed for single-config generators (Ninja, Make).
    # Multi-config generators (Visual Studio on Windows, Xcode on macOS) ignore it and use
    # the build preset's "configuration" field instead.  Omit it on MSVC to avoid the CMake
    # "unused-cli" warning.  On Windows the default generator is Visual Studio (multi-config);
    # on Linux/macOS it is Ninja/Make (single-config).
    local extra_args="-DCMAKE_BUILD_TYPE=Debug"
    case "$(uname -s)" in
        MINGW*|MSYS*|CYGWIN*|Windows*) extra_args="" ;; # multi-config
    esac
    local dirbase
    dirbase=$(basename "$1")
    local logfile="$WORK/build-${dirbase}.log"
    {
        echo "=== build_and_test: dir=$d extra_args=$extra_args ==="
        echo "=== cmake version: $(cmake --version | head -1) ==="
        echo "=== uname: $(uname -s) ==="
        echo "=== cygpath: $(command -v cygpath 2>/dev/null || echo not found) ==="
        echo "=== d after cygpath: $d ==="
    } >>"$logfile" 2>&1
    (cd "$d" && cmake --preset dev -DFETCHCONTENT_SOURCE_DIR_AW_CMAKE_MODULES="$ROOT_DIR" $extra_args >>"$logfile" 2>&1 && cmake --build --preset dev >>"$logfile" 2>&1) || {
        echo "=== cmake configure/build output ===" >&2
        cat "$logfile" >&2
        fail "build failed in $1"
    }
    if [ "$2" = 1 ]; then
        local tlog="$WORK/test-${dirbase}.log"
        (cd "$d" && ctest --preset dev >"$tlog" 2>&1) || {
            echo "=== ctest output ===" >&2
            cat "$tlog" >&2
            fail "tests failed in $1"
        }
    fi
}

if [ $# -gt 0 ]; then TYPES="$*"; else TYPES=$($SCAFFOLD list | grep -v '(internal:' | sed -n 's/^  \([^ ]*\) .*/\1/p'); fi
[ -n "$TYPES" ] || fail "no templates found"

# Filter out GUI template by default (GUI testing requires graphics environment and is covered separately in selftest.yml)
# Set RUN_GUI_TESTS=1 to include GUI template
if [ "${RUN_GUI_TESTS:-0}" != "1" ]; then
    TYPES=$(printf '%s\n' "$TYPES" | grep -v '^gui$' | paste -sd' ' -)
fi

section "generator checks"
d=$(newproj checks)
# shellcheck disable=SC2086
expect_fail "missing TYPE is rejected" $SCAFFOLD init --out "$d" --name x
# shellcheck disable=SC2086
expect_fail "unknown TYPE is rejected" $SCAFFOLD init nope --out "$d" --name x
# shellcheck disable=SC2086
expect_fail "bad NAME is rejected" $SCAFFOLD init static --out "$d" --name 'Bad Name'
# shellcheck disable=SC2086
expect_fail "keyword NAME is rejected" $SCAFFOLD init static --out "$d" --name class
# shellcheck disable=SC2086
expect_fail "bad NS is rejected" $SCAFFOLD init static --out "$d" --name x --ns 'aw::1bad'
# shellcheck disable=SC2086
expect_fail "keyword NS is rejected" $SCAFFOLD init static --out "$d" --name x --ns 'aw::new'
# shellcheck disable=SC2086
expect_fail "empty NS segment is rejected" $SCAFFOLD init static --out "$d" --name x --ns 'aw::::x'
# shellcheck disable=SC2086
$SCAFFOLD init lib --out "$d" --name x --dry-run | grep -q 'Template : static' || fail "alias lib -> static"
pass "alias lib resolves to static"
[ ! -e "$d/CMakeLists.txt" ] && [ ! -e "$d/src" ] || fail "dry run wrote files"
pass "dry run writes nothing"
# shellcheck disable=SC2010,SC2143
[ -z "$(ls -A "$d" | grep -v '^CMakePresets.json$')" ] || fail "dry run left stray files in output"

for t in $TYPES; do
    section "template: $t"
    d=$(newproj_ver "$t-hyphen")
    # shellcheck disable=SC2086
    echo y | $SCAFFOLD init "$t" --out "$d" --name my-lib --ns aw::foo::bar >/dev/null || fail "init $t failed"
    for p in CMakeLists.txt src include tests; do [ -e "$d/$p" ] || fail "$t: missing $p"; done
    [ -f "$d/include/aw/foo/bar/my_lib.hpp" ] || fail "$t: namespace/name path not rendered"
    grep -rq '@@' "$d/CMakeLists.txt" "$d/src" "$d/include" "$d/tests" && fail "$t: unresolved placeholder"
    grep -rq 'namespace aw::foo::bar {' "$d/include" || fail "$t: NS_OPEN not rendered"
    build_and_test "$d" 1
    pass "$t: init + build + ctest (NAME=my-lib NS=aw::foo::bar)"

    # Re-run over an existing project, without tests: must overwrite and drop tests/.
    # shellcheck disable=SC2086
    echo y | $SCAFFOLD init "$t" --out "$d" --name other --no-tests 2>"$WORK/warn.txt" >/dev/null || fail "$t: re-init failed"
    grep -q 'REPLACED\|overwriting' "$WORK/warn.txt" || fail "$t: no overwrite warning"
    [ ! -e "$d/tests" ] || fail "$t: tests/ not removed with --no-tests"
    [ ! -e "$d/include/aw/foo" ] || fail "$t: stale files survived re-init"
    build_and_test "$d" 0
    pass "$t: re-init overwrites with warning; --no-tests builds"

    # Name inferred from the directory, default namespace.
    d=$(newproj_ver "infer-$t/Inferred.Dir")
    # shellcheck disable=SC2086
    echo y | $SCAFFOLD init "$t" --out "$d" >/dev/null || fail "$t: init with inferred name failed"
    [ -f "$d/include/aw/unnamed/inferred_dir.hpp" ] || fail "$t: NAME inference / default NS failed"
    pass "$t: NAME inferred from directory, NS defaults to aw::unnamed"
done

section "static template extras"
# Skip expensive extras tests on constrained environments (Windows MSVC, TSan)
if [ "${SKIP_TEMPLATE_EXTRAS:-0}" = "1" ]; then
    pass "static: examples/, alias, FILE_SET and options rendered (skipped)"
    pass "static: -Werror build, tests, examples and install (skipped)"
    pass "static: installed package works with find_package(tobus) + aw::tobus (skipped)"
    pass "static: options default to OFF as a subproject (skipped)"
else
    d=$(newproj_ver static-extras)
    # shellcheck disable=SC2086
    echo y | $SCAFFOLD init static --out "$d" --name tobus --ns aw::tobus >/dev/null || fail "static extras: init failed"
    for p in examples/CMakeLists.txt examples/01_basic.cpp; do [ -e "$d/$p" ] || fail "static: missing $p"; done
    grep -q 'aw_add_library(TARGET tobus TYPE STATIC ALIAS aw::tobus' "$d/CMakeLists.txt" || fail "static: alias is not the namespace"
    grep -q 'HEADERS include/aw/tobus/tobus.hpp' "$d/CMakeLists.txt" || fail "static: no public headers"
    grep -q 'aw_project_setup(PREFIX TOBUS BUILD_EXAMPLES BUILD_TESTS INSTALL)' "$d/CMakeLists.txt" || fail "static: missing shared project options"
    pass "static: examples/, alias, FILE_SET and options rendered"

    dd=$d
    if command -v cygpath >/dev/null 2>&1; then dd=$(cygpath -m "$d"); fi
    inst="$WORK/static-extras-inst"
    (cd "$dd" && cmake -B build/x -DCMAKE_BUILD_TYPE=Debug -DTOBUS_WARNINGS_AS_ERRORS=ON -DCMAKE_INSTALL_PREFIX="$inst" -DFETCHCONTENT_SOURCE_DIR_AW_CMAKE_MODULES="$ROOT_DIR" >"$WORK/x.log" 2>&1 \
        && cmake --build build/x >>"$WORK/x.log" 2>&1 && ctest --test-dir build/x >>"$WORK/x.log" 2>&1 \
        && cmake --install build/x --config Debug >>"$WORK/x.log" 2>&1) || { cat "$WORK/x.log" >&2; fail "static: strict build/test/install failed"; }
    pass "static: -Werror build, tests, examples and install"

    # A consumer finds the installed package and links the alias.
    mkdir -p "$WORK/consumer"
    cat >"$WORK/consumer/CMakeLists.txt" <<'EOC'
cmake_minimum_required(VERSION 3.23)
project(consumer CXX)
find_package(tobus REQUIRED)
add_executable(c c.cpp)
target_link_libraries(c PRIVATE aw::tobus)
EOC
    cat >"$WORK/consumer/c.cpp" <<'EOC'
#include <aw/tobus/tobus.hpp>
int main() { return aw::tobus::greet("x").empty() ? 1 : 0; }
EOC
    cw="$WORK/consumer"
    if command -v cygpath >/dev/null 2>&1; then cw=$(cygpath -m "$cw"); inst=$(cygpath -m "$inst"); fi
    (cd "$cw" && cmake -B b -DCMAKE_BUILD_TYPE=Debug -DCMAKE_PREFIX_PATH="$inst" >"$WORK/c.log" 2>&1 \
        && cmake --build b --config Debug >>"$WORK/c.log" 2>&1) || { cat "$WORK/c.log" >&2; fail "static: find_package consumer failed"; }
    pass "static: installed package works with find_package(tobus) + aw::tobus"

    # Used as a subproject, tests/examples/install default to OFF.
    mkdir -p "$WORK/subproj"
    printf 'cmake_minimum_required(VERSION 3.23)\nproject(sub CXX)\nadd_subdirectory("%s" lib)\nmessage(STATUS "SUB_TESTS=${TOBUS_BUILD_TESTS}")\n' "$dd" >"$WORK/subproj/CMakeLists.txt"
    (cd "$WORK/subproj" && cmake -B b -DFETCHCONTENT_SOURCE_DIR_AW_CMAKE_MODULES="$ROOT_DIR" 2>&1 | grep -q 'SUB_TESTS=OFF') || fail "static: tests not OFF when used as a subproject"
    pass "static: options default to OFF as a subproject"
fi

section "out directory"
if [ "${SKIP_TEMPLATE_EXTRAS:-0}" = "1" ]; then
    pass "AW_OUT selects the output directory (skipped)"
else
    d=$(newproj_ver out-var)
    (cd "$ROOT_DIR" && echo y | AW_OUT="$d" AW_TYPE=static AW_NAME=x $SCAFFOLD init >/dev/null) || fail "AW_OUT init failed"
    [ -f "$d/CMakeLists.txt" ] || fail "AW_OUT was not honoured"
    pass "AW_OUT selects the output directory"
fi

section "eject"
if [ "${SKIP_TEMPLATE_EXTRAS:-0}" = "1" ]; then
    pass "eject removes templates/ (skipped)"
else
    # Run eject on a copy so the real templates/ stays intact.
    mkdir -p "$WORK/eject/templates"
    cp "$TPL_DIR/scaffold.sh" "$WORK/eject/templates/"
    bash "$WORK/eject/templates/scaffold.sh" eject >/dev/null || fail "eject failed"
    [ ! -e "$WORK/eject/templates" ] || fail "eject left templates/"
    pass "eject removes templates/"
fi

printf '\nAll selftests passed.\n'
