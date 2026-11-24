#!/usr/bin/env bash
# scaffold.sh — minimal `dotnet new`-style project generator (pure Bash 3.2+; Linux / macOS / Git Bash).
#
#   scaffold.sh list
#   scaffold.sh init [TYPE] [--name NAME] [--ns NAMESPACE] [--no-tests] [--dry-run] [--out DIR]
#   scaffold.sh eject
#
# A template is a folder:  templates/<type>/{template.conf, files/}.  `files/` mirrors the project root and is
# rendered by replacing @@KEY@@ placeholders in file contents *and* in file/directory names (see KEYS below).
# Templates are auto-discovered; adding one needs no change to this script.
#
# Defaults can also come from the environment (this is how the Makefile passes them):
#   AW_TYPE, AW_NAME, AW_NS (default aw::unnamed), AW_TESTS (1|0, default 1), AW_DRY (1|0), AW_OUT (output dir)
set -eu
shopt -u patsub_replacement 2>/dev/null || true # Bash 5.2: keep '&' literal in replacements

TPL_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(dirname "$TPL_DIR")

# Top-level entries a template may produce. `init` replaces exactly these, so re-running it is idempotent.
# (`examples` is only replaced when the template produces it, so hand-written examples/ survive other templates.)
MANAGED="CMakeLists.txt src include tests examples .github README.md LICENSE .gitignore CMakePresets.json CHANGELOG.md"

# Shared files/dirs copied as-is from the repository root into the generated project.
# Not rendered (no @@KEY@@ processing) — just cp.
SHARED_FILES=".clang-format .clang-tidy .editorconfig .gitattributes VERSION"
# .example files copied as-is, stripping the .example suffix (e.g. CMakeUserPresets.json.example → CMakeUserPresets.json).
EXAMPLE_FILES="CMakeUserPresets.json.example"
KEYS="NAME NAME_ID NAME_UPPER NS NS_OPEN NS_CLOSE NS_PATH NS_UPPER MACRO_PREFIX TYPE"
LEFTOVER_RE='@@[A-Z0-9_]+@@'
NAME_RE='^[a-z][a-z0-9_-]*$'
IDENT_RE='^[A-Za-z][A-Za-z0-9_]*$'

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
warn() { printf 'warning: %s\n' "$*" >&2; }
say() { printf '%s\n' "$*"; }

KEYWORDS=" alignas alignof and and_eq asm auto bitand bitor bool break case catch char char8_t char16_t char32_t class
 compl concept const consteval constexpr constinit const_cast continue co_await co_return co_yield decltype default
 delete do double dynamic_cast else enum explicit export extern false float for friend goto if inline int long main
 mutable namespace new noexcept not not_eq nullptr operator or or_eq private protected public register
 reinterpret_cast requires return short signed sizeof static static_assert static_cast struct switch template this
 thread_local throw true try typedef typeid typename union unsigned using virtual void volatile wchar_t while xor
 xor_eq std "

is_keyword() {
    local k=${KEYWORDS//$'\n'/ }
    case "$k" in *" $1 "*) return 0 ;; esac
    return 1
}

# shellcheck disable=SC2018,SC2019
upper() { printf '%s' "$1" | LC_ALL=C tr 'a-z-' 'A-Z_'; }

# ── template discovery ───────────────────────────────────────────────────────────────────────────────────────────
list_types() {
    local d
    for d in "$TPL_DIR"/*/; do
        [ -f "${d}template.conf" ] && basename "$d"
    done
    return 0
}

# conf_get TYPE VAR — read DESCRIPTION / ALIASES from templates/TYPE/template.conf (sourced in a subshell).
conf_get() {
    (
        # shellcheck disable=SC2034
        DESCRIPTION=''
        # shellcheck disable=SC2034
        ALIASES=''
        # shellcheck disable=SC1090
        . "$TPL_DIR/$1/template.conf"
        printf '%s' "${!2}"
    )
}

resolve_type() {
    local want t a
    # shellcheck disable=SC2018,SC2019
    want=$(printf '%s' "$1" | LC_ALL=C tr 'A-Z' 'a-z')
    for t in $(list_types); do
        [ "$t" = "$want" ] && { printf '%s' "$t"; return 0; }
        for a in $(conf_get "$t" ALIASES); do
            [ "$a" = "$want" ] && { printf '%s' "$t"; return 0; }
        done
    done
    printf "error: unknown template type '%s'\n\n" "$1" >&2
    cmd_list >&2
    exit 1
}

cmd_list() {
    local t aliases
    say "Available templates:"
    for t in $(list_types); do
        aliases=$(conf_get "$t" ALIASES)
        printf '  %-10s %s%s\n' "$t" "$(conf_get "$t" DESCRIPTION)" "${aliases:+  (aliases: ${aliases})}"
    done
}

usage() {
    cat <<'EOF'
Usage:
  scaffold.sh list
  scaffold.sh init [TYPE] [--name NAME] [--ns NAMESPACE] [--no-tests] [--dry-run] [--out DIR]
  scaffold.sh eject

Options for init:
  --name NAME     project name, [a-z][a-z0-9_-]*   (default: the output directory's name)
  --ns NAMESPACE  C++ namespace, e.g. aw::foo      (default: aw::unnamed)
  --no-tests      skip tests/ (and the Catch2 FetchContent setup)
  --dry-run       show what would be generated; write nothing
  --out DIR       generate into DIR instead of the repository root (make: OUT=DIR)
EOF
}

# ── validation / derivation ──────────────────────────────────────────────────────────────────────────────────────
infer_name() {
    local b
    # shellcheck disable=SC2018,SC2019
    b=$(basename "$1" | LC_ALL=C tr 'A-Z' 'a-z' | LC_ALL=C tr ' .' '--' | LC_ALL=C tr -cd 'a-z0-9_-')
    while [ -n "$b" ] && [[ $b != [a-z]* ]]; do b=${b#?}; done
    printf '%s' "$b"
}

validate_name() {
    [[ $1 =~ $NAME_RE ]] || die "invalid NAME '$1': use lowercase letters, digits, '-' or '_', starting with a letter"
    local id=${1//-/_}
    case $id in *__*) die "invalid NAME '$1': '__' is reserved in C++ identifiers" ;; esac
    ! is_keyword "$id" || die "invalid NAME '$1': '$id' is a C++ keyword"
}

validate_ns() {
    local rest=$1 part
    [ -n "$rest" ] || die "namespace must not be empty"
    while :; do
        part=${rest%%::*}
        [[ $part =~ $IDENT_RE ]] || die "invalid NS '$1': '$part' is not a valid identifier (expected e.g. aw::foo)"
        case $part in *__*) die "invalid NS '$1': '__' is reserved in C++ identifiers" ;; esac
        ! is_keyword "$part" || die "invalid NS '$1': '$part' is a C++ keyword or reserved"
        [ "$part" = "$rest" ] && break
        rest=${rest#*::}
    done
}

# ── rendering ────────────────────────────────────────────────────────────────────────────────────────────────────
# render_text STRING -> $REPLY
render_text() {
    local s=$1 k v
    for k in $KEYS; do
        v=P_$k
        v=${!v}
        s=${s//"@@$k@@"/$v}
    done
    REPLY=$s
}

render_file() { # SRC DST
    local line n=0
    while IFS= read -r line || [ -n "$line" ]; do
        n=$((n + 1))
        render_text "$line"
        if [[ $REPLY =~ $LEFTOVER_RE ]]; then
            die "unresolved placeholder ${BASH_REMATCH[0]} in ${1#"$TPL_DIR"/}:$n"
        fi
        printf '%s\n' "$REPLY"
    done <"$1" >"$2"
}

# ── commands ─────────────────────────────────────────────────────────────────────────────────────────────────────
# shellcheck disable=SC2034
cmd_init() {
    local type=${AW_TYPE:-} name=${AW_NAME:-} ns=${AW_NS:-aw::unnamed} tests=${AW_TESTS:-1} dry=${AW_DRY:-0} out=${AW_OUT:-$ROOT_DIR}
    while [ $# -gt 0 ]; do
        case $1 in
            --name) [ $# -ge 2 ] || die "--name needs a value"; name=$2; shift ;;
            --ns) [ $# -ge 2 ] || die "--ns needs a value"; ns=$2; shift ;;
            --out) [ $# -ge 2 ] || die "--out needs a value"; out=$2; shift ;;
            --no-tests) tests=0 ;;
            --dry-run) dry=1 ;;
            -*) die "unknown option '$1' (try 'help')" ;;
            *) type=$1 ;;
        esac
        shift
    done
    [ -n "$ns" ] || ns=aw::unnamed
    case $tests in 0 | no | off | false | NO | OFF | FALSE) tests=0 ;; *) tests=1 ;; esac
    case $dry in 1 | yes | on | true | YES | ON | TRUE) dry=1 ;; *) dry=0 ;; esac

    if [ -z "$type" ]; then
        printf 'error: missing template TYPE\n\n' >&2
        cmd_list >&2
        printf '\nExample: make init TYPE=static NAME=my-lib NS=aw::foo\n' >&2
        exit 2
    fi
    type=$(resolve_type "$type")

    if [ ! -d "$out" ]; then
        mkdir -p "$out" || die "could not create output directory '$out'"
    fi
    out=$(cd "$out" && pwd)
    case $out/ in "$TPL_DIR"/*) die "refusing to generate inside templates/" ;; esac
    if [ "$out" = "$ROOT_DIR" ] && [ "${AW_FORCE_ROOT:-0}" != 1 ]; then
        die "refusing to generate into the template generator repository; pass --out DIR to target a separate directory"
    fi

    if [ -z "$name" ]; then
        name=$(infer_name "$out")
        [ -n "$name" ] || die "cannot infer NAME from directory '$(basename "$out")'; pass NAME=<name>"
        say "note: NAME not given, using '$name' (from directory name)"
    fi
    validate_name "$name"
    validate_ns "$ns"

    # Placeholder values (see KEYS).
    local slash=/ ns_up
    ns_up=$(upper "${ns//::/_}")
    P_NAME=$name
    P_NAME_ID=${name//-/_}
    P_NAME_UPPER=$(upper "$name")
    P_NS=$ns
    P_NS_OPEN="namespace $ns {"
    P_NS_CLOSE="} // namespace $ns"
    P_NS_PATH=${ns//::/$slash}
    P_NS_UPPER=$ns_up
    P_MACRO_PREFIX=${ns_up}_${P_NAME_UPPER}
    P_TYPE=$type

    # Render into a staging dir first so a failure never leaves a half-generated project behind.
    local stage src rel dst files top count=0 kept=''
    if [ "$dry" = 1 ]; then
        stage=$(mktemp -d "${TMPDIR:-/tmp}/aw-scaffold.XXXXXX")
    else
        stage=$(mktemp -d "$out/.scaffold.XXXXXX")
    fi
    # shellcheck disable=SC2064
    trap "rm -rf '${stage:?}'" EXIT

    src=$TPL_DIR/$type/files
    [ -d "$src" ] || die "template '$type' has no files/ directory"
    files=$(cd "$src" && find . -type f | LC_ALL=C sort)
    while IFS= read -r rel; do
        [ -n "$rel" ] || continue
        rel=${rel#./}
        [ "$tests" = 1 ] || case $rel in tests/*) continue ;; esac
        render_text "$rel"
        dst=$REPLY
        if [[ $dst =~ $LEFTOVER_RE ]]; then die "unresolved placeholder ${BASH_REMATCH[0]} in path '$rel'"; fi
        top=${dst%%/*}
        case " $MANAGED " in *" $top "*) ;; *) die "template '$type' produces '$top', which is not one of: $MANAGED" ;; esac
        mkdir -p "$stage/$(dirname "$dst")"
        render_file "$src/$rel" "$stage/$dst"
        kept="$kept$dst
"
        count=$((count + 1))
    done <<EOF
$files
EOF
    [ "$count" -gt 0 ] || die "template '$type' generated no files"

    # Process _common template files (if any), overlaying them on top of template-specific files.
    common_src=$TPL_DIR/_common/files
    if [ -d "$common_src" ]; then
        common_files=$(cd "$common_src" && find . -type f | LC_ALL=C sort)
        while IFS= read -r rel; do
            [ -n "$rel" ] || continue
            rel=${rel#./}
            [ "$tests" = 1 ] || case $rel in tests/*) continue ;; esac
            render_text "$rel"
            dst=$REPLY
            if [[ $dst =~ $LEFTOVER_RE ]]; then die "unresolved placeholder ${BASH_REMATCH[0]} in path '$rel' (_common)"; fi
            top=${dst%%/*}
            case " $MANAGED " in *" $top "*) ;; *) die "_common template produces '$top', which is not one of: $MANAGED" ;; esac
            mkdir -p "$stage/$(dirname "$dst")"
            render_file "$common_src/$rel" "$stage/$dst"
            kept="$kept$dst
"
            count=$((count + 1))
        done <<EOF
$common_files
EOF
    fi

    # Copy shared files/dirs from the repository root into the staging dir.
    # These are not rendered — just copied as-is.
    for item in $SHARED_FILES; do
        [ -e "$ROOT_DIR/$item" ] || die "SHARED_FILES references '$item' but it does not exist in $ROOT_DIR"
        if [ -d "$ROOT_DIR/$item" ]; then
            cp -r "$ROOT_DIR/$item" "$stage/$item"
        else
            cp "$ROOT_DIR/$item" "$stage/$item"
        fi
    done

    # Copy .example files from the repository root, stripping the .example suffix.
    for src in $EXAMPLE_FILES; do
        local base=${src%.example}
        [ -e "$ROOT_DIR/$src" ] || die "EXAMPLE_FILES references '$src' but it does not exist in $ROOT_DIR"
        cp "$ROOT_DIR/$src" "$stage/$base"
    done

    local existing='' m
    for m in $MANAGED; do
        [ "$m" = examples ] && [ ! -e "$stage/examples" ] && continue
        [ -e "$out/$m" ] && existing="$existing $m"
    done

    # Check if output directory is not empty (excluding .git and other hidden dirs that may exist)
    local other_files=''
    if [ "$(find "$out" -maxdepth 1 -not -path '*/.*' -type f 2>/dev/null | wc -l)" -gt 0 ] || \
       [ "$(find "$out" -maxdepth 1 -not -path '*/.*' -type d 2>/dev/null | wc -l)" -gt 1 ]; then
        other_files=1
    fi

    say "Template : $type"
    say "Name     : $name   (id: $P_NAME_ID)"
    say "Namespace: $ns"
    say "Tests    : $([ "$tests" = 1 ] && echo 'Catch2 v3 via FetchContent' || echo 'none (--no-tests)')"
    say "Output   : $out"
    say ""

    if [ "$dry" = 1 ]; then
        say "Dry run — would generate $count files:"
        printf '%s' "$kept" | sed 's/^/  /'
        [ -z "$existing" ] || say "and would REPLACE existing:$existing"
        return 0
    fi

    # Prompt before merging into non-empty directory
    if [ -n "$existing" ] || [ -n "$other_files" ]; then
        if [ -n "$existing" ]; then
            warn "The following managed files will be REPLACED unconditionally:$existing"
        fi
        if [ -n "$other_files" ]; then
            warn "Output directory '$out' is not empty — existing files will be merged with generated content."
        fi
        if [ -t 0 ]; then
            printf 'Proceed? [y/N] ' >&2
            read -r answer
            case $answer in
                [Yy] | [Yy][Ee][Ss]) : ;;
                *) say "Aborted."; exit 0 ;;
            esac
        fi
    fi
    for m in $MANAGED; do
        [ "$m" = examples ] && [ ! -e "$stage/examples" ] && continue
        rm -rf "${out:?}/$m"
    done
    for m in $(cd "$stage" && ls -A); do
        mv "$stage/$m" "$out/$m"
    done

    say "Generated $count files:"
    printf '%s' "$kept" | sed 's/^/  /'
    say ""
    say "Next steps:"
    if [ "$out" = "$ROOT_DIR" ] && [ -f "$out/Makefile" ]; then
        say "  make test    # configure + build + run tests"
        say "  make build   # configure + build"
    fi
    say "  cmake --preset dev && cmake --build --preset dev$([ "$tests" = 1 ] && echo ' && ctest --preset dev')"
    if [ "$out" = "$ROOT_DIR" ]; then
        say ""
        say "Tip: the generator is no longer needed once you have your project — run 'make eject' to remove templates/."
    fi
}

cmd_eject() {
    [ "$(basename "$TPL_DIR")" = templates ] || die "refusing to eject: '$TPL_DIR' is not a templates/ directory"
    rm -rf "${TPL_DIR:?}" || die "could not remove $TPL_DIR (is a file in it open? try 'make eject')"
    say "Removed templates/. Re-add it from git history or the upstream template if you need the generator again."
}

main() {
    local cmd=${1:-help}
    [ $# -eq 0 ] || shift
    case $cmd in
        list) cmd_list ;;
        init | new) cmd_init "$@" ;;
        eject) cmd_eject ;;
        help | -h | --help) usage ;;
        *) usage >&2; die "unknown command '$cmd'" ;;
    esac
}

main "$@"
exit $?
