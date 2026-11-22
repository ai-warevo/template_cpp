# ── aw::template_cpp ─────────────────────────────────────────────────
# `dotnet new`-style generator + everyday build targets for the generated project.
#
#   make init TYPE=<type> [NAME=<name>] [NS=<namespace>] [OUT=<dir>] [TESTS=0] [DRY=1]
#   make list        list templates (and aliases)
#   make selftest    generate + build + test every template (needs cmake, a compiler, network for Catch2)
#   make eject       remove templates/ once you no longer need the generator
#
#   make build | test | lint | format | clean      (BUILD_TYPE=Debug|Release, default Debug)
#
# Examples (generate in SEPARATE directory, not template_cpp root):
#   make init TYPE=gui NAME=myapp NS=aw::myapp OUT=../my-gui-app
#   make init TYPE=static NAME=mylib NS=aw::foo OUT=../my-static-lib
#   make init TYPE=cli OUT=../my-cli-tool           # NAME inferred from OUT directory name
#
# Values reach scaffold.sh through the environment (AW_*), so no shell quoting is needed for NS=aw::foo etc.

SCAFFOLD := bash templates/scaffold.sh
PRESET   := $(if $(filter Release,$(BUILD_TYPE)),release,debug)

# Only honour variables given on the command line: NAME/TYPE often exist in the user's environment already.
ifeq ($(origin TYPE),command line)
export AW_TYPE := $(TYPE)
endif
ifeq ($(origin NAME),command line)
export AW_NAME := $(NAME)
endif
ifeq ($(origin NS),command line)
export AW_NS := $(NS)
endif
ifeq ($(origin TESTS),command line)
export AW_TESTS := $(TESTS)
endif
ifeq ($(origin OUT),command line)
export AW_OUT := $(OUT)
endif
ifeq ($(origin DRY),command line)
export AW_DRY := $(DRY)
endif

.DEFAULT_GOAL := help
.PHONY: help list init selftest eject build test lint format clean

help:
	@echo "aw::template_cpp — C++23 project generator"
	@echo ""
	@echo "Generator:"
	@echo "  make init TYPE=<type> [NAME=<name>] [NS=<ns>] [OUT=<dir>] [TESTS=0] [DRY=1]"
	@echo "  make list        list templates"
	@echo "  make selftest    verify every template builds and passes its tests"
	@echo "  make eject       remove templates/"
	@echo ""
	@echo "Project (after generation):"
	@echo "  make build | test | lint | format | clean   (BUILD_TYPE=Release for release)"
	@echo ""
	@echo "Quick start:"
	@echo "  make init TYPE=gui NAME=myapp NS=aw::myapp OUT=../my-gui-app"
	@echo "  cd ../my-gui-app && cmake --preset dev && cmake --build --preset dev"
	@echo ""
	@if [ -f templates/scaffold.sh ]; then $(SCAFFOLD) list; else echo "(templates/ has been ejected)"; fi

list init selftest:
	@if [ ! -f templates/scaffold.sh ]; then echo "error: templates/ not found (already ejected?)" >&2; exit 1; fi
	@$(if $(filter selftest,$@),bash templates/selftest.sh,$(SCAFFOLD) $@)

eject:
	@$(SCAFFOLD) eject

# ── project targets ──────────────────────────────────────────────────
build:
	cmake -B build/$(PRESET) -DCMAKE_BUILD_TYPE=$(BUILD_TYPE) -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
	cmake --build build/$(PRESET)

test: build
	@if [ -f tests/CMakeLists.txt ]; then ctest --test-dir build/$(PRESET) --output-on-failure --parallel 4; \
	else echo "No tests/ directory (generated with TESTS=0)."; fi

lint: build
	@if command -v clang-tidy >/dev/null 2>&1; then \
	    find include src -name '*.hpp' -o -name '*.cpp' | xargs clang-tidy -p build/$(PRESET) --warnings-as-errors='*'; \
	else echo "clang-tidy not found"; fi

format:
	@if command -v clang-format >/dev/null 2>&1; then \
	    find include src tests -name '*.hpp' -o -name '*.cpp' 2>/dev/null | xargs clang-format -i; \
	else echo "clang-format not found (>= 15 required)"; fi

clean:
	rm -rf build
