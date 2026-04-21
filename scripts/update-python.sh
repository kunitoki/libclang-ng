#!/bin/sh
set -eu

TOP_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$TOP_DIR"

LLVM_VER="${LLVM_VER:-$(python3 -c "import sys; sys.path.insert(0, 'python'); from clang import __version__; print(__version__)")}"
LLVM_VER_MAJOR="$(echo "$LLVM_VER" | cut -d. -f1)"
LLVM_BINDINGS="${TOP_DIR}/build/llvm/src/clang/bindings/python/clang"
SRC_DIR="${TOP_DIR}/build/src/clang"

if [ ! -d "${TOP_DIR}/build/llvm/src" ]; then
    echo "error: build/llvm/src not found — run 'just download-llvm' first" >&2
    exit 1
fi

# Rebuild build/src/clang/ from scratch
rm -rf "$SRC_DIR"
mkdir -p "$SRC_DIR"

# Seed with our local python/clang/ (enumerations.py, native/, etc.)
cp -r "${TOP_DIR}/python/clang/." "$SRC_DIR/"
rm -rf "${SRC_DIR}/native/.gitignore"
rm -rf "${SRC_DIR}/__pycache__"

# Overlay with the LLVM bindings matching the version being compiled
cp "${LLVM_BINDINGS}/__init__.py" "${SRC_DIR}/__init__.py"
cp "${LLVM_BINDINGS}/cindex.py" "${SRC_DIR}/cindex.py"

# Apply our patch (run from build/src so -p2 strips a/python/ → clang/cindex.py)
cd "${TOP_DIR}/build/src"
patch -p2 < "${TOP_DIR}/scripts/data/clang_bindings_${LLVM_VER_MAJOR}.patch"
rm -f "${SRC_DIR}/cindex.py.orig"

# Restore __version__ (upstream __init__.py does not carry it)
uv run python -c "
import pathlib, sys
ver, path = sys.argv[1], sys.argv[2]
p = pathlib.Path(path)
content = p.read_text()
if '__version__' not in content:
    content = content.replace('__all__', '__version__ = \"' + ver + '\"\\n__all__', 1)
    p.write_text(content)
" "$LLVM_VER" "${SRC_DIR}/__init__.py"

echo "build/src/clang/ prepared with LLVM ${LLVM_VER} bindings"
