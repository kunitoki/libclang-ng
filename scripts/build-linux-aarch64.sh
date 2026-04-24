#!/bin/sh
set -eu

TOP_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$TOP_DIR"

BUILD_DIR="${TOP_DIR}/build/llvm/cmake-build"

mkdir -p "$BUILD_DIR"

if [ -f "$BUILD_DIR/lib/libclang.so" ]; then
    echo "libclang.so already built, skipping build"
    exit 0
fi

CCACHE_DIR="${CCACHE_DIR:-${TOP_DIR}/.ccache}"
mkdir -p "${CCACHE_DIR}"

sudo docker run --privileged --network=host --rm \
    --platform linux/arm64 \
    -v "${TOP_DIR}:/work" \
    -v "${CCACHE_DIR}:/ccache" \
    -e CCACHE_DIR=/ccache \
    quay.io/pypa/manylinux2014_aarch64:latest \
    sh -c 'yum install -y epel-release && yum install -y ccache && \
           mkdir -p /work/build/llvm/cmake-build && \
           cd /work/build/llvm/cmake-build && \
           cmake /work/build/llvm/src/llvm \
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
             "-DCMAKE_CXX_FLAGS_RELEASE=-O2 -g -DNDEBUG -static-libgcc -static-libstdc++" \
             -DCMAKE_C_COMPILER_LAUNCHER=ccache \
             -DCMAKE_CXX_COMPILER_LAUNCHER=ccache && \
           make libclang -j$(nproc) && \
           strip lib/libclang.so'

sudo chmod -R a+wr "${TOP_DIR}/build/llvm/cmake-build"
sudo chmod -R a+wr "${CCACHE_DIR}"

echo ""
echo "=== build output ==="
du -csh "$BUILD_DIR/lib/libclang.so"
file "$BUILD_DIR/lib/libclang.so"
ldd "$BUILD_DIR/lib/libclang.so"
