#!/bin/sh
set -eu

TOP_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$TOP_DIR"

PKG_VER="${PKG_VER:-$(python3 -c "import sys; sys.path.insert(0, 'python'); from clang import __version__; print(__version__)")}"
LLVM_VER="${LLVM_VER:-$(echo "$PKG_VER" | cut -d. -f1-3)}"
TARBALL="llvm-project-${LLVM_VER}.src.tar.xz"
DEST_DIR="${TOP_DIR}/build/llvm/src"

if [ -d "$DEST_DIR" ]; then
    echo "build/llvm/src already present, skipping download"
    exit 0
fi

mkdir -p "${TOP_DIR}/build/llvm"

echo "Downloading LLVM ${LLVM_VER}..."
curl -fL -o "${TOP_DIR}/build/$TARBALL" "https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VER}/${TARBALL}"
tar xf "${TOP_DIR}/build/$TARBALL" -C "${TOP_DIR}/build/" --exclude='llvm-project-*/clang/test' --exclude='llvm-project-*/llvm/test'
mv "${TOP_DIR}/build/llvm-project-${LLVM_VER}.src" "$DEST_DIR"
rm "${TOP_DIR}/build/$TARBALL"
echo "LLVM ${LLVM_VER} source ready in build/llvm/src/"
