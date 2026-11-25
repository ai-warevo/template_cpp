# syntax=docker/dockerfile:1.7
#
# CI image for C++23 projects (tpl / tobus).
# Pushed to ghcr.io/ai-warevo/ci-cpp23 on tag.
#
# Toolchains:
#   gcc-15 (libstdc++) — default gcc/g++ (from Debian forky/unstable)
#   clang-18 (libc++)   — clang++-18 -stdlib=libc++ (from Debian trixie)
#   clang-18 (libstdc++) — clang++-18, default stdlib (from Debian trixie)
# Linters:
#   clang-tidy-18 (from Debian trixie)
#   clang-format-18 (>= 15, from Debian trixie)
# Bundled: cmake, ninja-build, gcovr (forky), gdb, lld, ASan/TSan runtimes
#
# Usage in GitHub Actions:
#   runs-on: ubuntu-latest
#   container: ghcr.io/ai-warevo/ci-cpp23:<tag>
#   (no setup-toolchain action needed)

FROM debian:trixie

ENV DEBIAN_FRONTEND=noninteractive

# Add forky (unstable) repo with low priority so it doesn't override trixie packages.
RUN echo 'deb https://deb.debian.org/debian forky main' > /etc/apt/sources.list.d/forky.list && \
    printf 'Package: *\nPin: release n=forky\nPin-Priority: 100\n' > /etc/apt/preferences.d/forky && \
    apt-get update && \
    # Main packages from trixie
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        ccache \
        clang-18 \
        clang-format-18 \
        clang-tidy-18 \
        cmake \
        gdb \
        gperf \
        git \
        libssl-dev \
        lld-18 \
        libc++-18-dev \
        libc++abi-18-dev \
        libunwind-18-dev \
        libclang-rt-18-dev \
        ninja-build \
        qrencode \
        zlib1g-dev && \
    apt-get update && \
    # gcc-15 and matching gcovr from forky (unstable)
    apt-get install -y --no-install-recommends -t forky \
        gcc-15 \
        g++-15 \
        gcovr && \
    rm -rf /var/lib/apt/lists/* && \
    ln -sf /usr/bin/gcc-15 /usr/bin/gcc && \
    ln -sf /usr/bin/g++-15 /usr/bin/g++ && \
    ln -sf /usr/bin/clang-tidy-18 /usr/bin/clang-tidy && \
    ln -sf /usr/bin/clang-format-18 /usr/bin/clang-format && \
    g++-15 --version && \
    clang++-18 --version

# Pre-populate stable third-party dependencies into /opt/deps for local-first caching
ENV AW_DEPS_DIR=/opt/deps
RUN mkdir -p /opt/deps/src && \
    cd /opt/deps/src && \
    # Catch2 v3.6.0 (used by template_cpp, spoofiq)
    git clone --branch v3.6.0 --depth 1 https://github.com/catchorg/Catch2.git && \
    cd Catch2 && mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/deps -DBUILD_TESTING=OFF && \
    cmake --build . --parallel && cmake --install . && \
    echo 'set(Catch2_SOURCE_DIR "/opt/deps/src/Catch2")' >> /opt/deps/lib/cmake/Catch2/Catch2Config.cmake && \
    cd /opt/deps/src && \
    # spdlog v1.14.1 (used by gitsync, spoofiq)
    git clone --branch v1.14.1 --depth 1 https://github.com/gabime/spdlog.git && \
    cd spdlog && mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/deps -DSPDLOG_BUILD_TESTS=OFF -DSPDLOG_BUILD_EXAMPLE=OFF && \
    cmake --build . --parallel && cmake --install . && \
    cd /opt/deps/src && rm -rf spdlog && \
    # nlohmann/json v3.11.3 (used by gitsync, tobus, spoofiq)
    git clone --branch v3.11.3 --depth 1 https://github.com/nlohmann/json.git && \
    cd json && mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/deps -DJSON_BuildTests=OFF && \
    cmake --build . --parallel && cmake --install . && \
    cd /opt/deps/src && rm -rf json && \
    # STB (header-only image library, used by spoofiq)
    git clone --depth 1 https://github.com/nothings/stb.git && \
    mkdir -p /opt/deps/include/stb && \
    cp stb/*.h /opt/deps/include/stb/ && \
    rm -rf stb && \
    # fmt v11 (optional, modern C++ formatting library)
    git clone --branch 11.0.2 --depth 1 https://github.com/fmtlib/fmt.git && \
    cd fmt && mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/deps -DFMT_TEST=OFF && \
    cmake --build . --parallel && cmake --install . && \
    cd /opt/deps/src && rm -rf fmt && \
    # TDLib (Telegram Database Library, for future Telegram app)
    git clone --depth 1 https://github.com/tdlib/td.git && \
    cd td && mkdir build && cd build && \
    CXXFLAGS="-stdlib=libc++" CC=/usr/bin/clang-18 CXX=/usr/bin/clang++-18 \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/deps \
        -DTD_ENABLE_LTO=ON -DTD_ENABLE_PCH=ON && \
    cmake --build . -j$(nproc) --target install && \
    cd /opt/deps/src && rm -rf td && \
    # Cleanup: keep Catch2 sources for aw_test_target, remove others
    cd / && rm -rf /opt/deps/src/spdlog /opt/deps/src/json /opt/deps/src/stb /opt/deps/src/fmt
