#!/bin/sh
set -eu

TOP_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$TOP_DIR"

MACOSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-10.15}"
BUILD_DIR="${TOP_DIR}/build/llvm/cmake-build"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

if [ -f "lib/libclang.dylib" ]; then
    echo "libclang.dylib already built, skipping build"
    exit 0
fi

cmake "${TOP_DIR}/build/llvm/src/llvm" \
    -DLLVM_ENABLE_PROJECTS=clang \
    -DBUILD_SHARED_LIBS=OFF \
    -DLLVM_ENABLE_ZLIB=OFF \
    -DLLVM_ENABLE_ZSTD=OFF \
    -DLLVM_ENABLE_TERMINFO=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_DOCS=OFF \
    -DCLANG_INCLUDE_TESTS=OFF \
    -DCLANG_INCLUDE_DOCS=OFF \
    -DLLVM_TARGETS_TO_BUILD=AArch64 \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_FLAGS_RELEASE="-O2 -g -DNDEBUG -static-libgcc -static-libstdc++" \
    -DCMAKE_C_COMPILER="$(brew --prefix gcc@14)/bin/gcc-14" \
    -DCMAKE_CXX_COMPILER="$(brew --prefix gcc@14)/bin/g++-14" \
    -DCMAKE_C_COMPILER_LAUNCHER=ccache \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET}"

make libclang -j"$(sysctl -n hw.ncpu)"

echo ""
echo "=== build output ==="
du -csh lib/libclang.dylib
file lib/libclang.dylib
otool -L lib/libclang.dylib
