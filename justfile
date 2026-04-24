default:
    @just --list

# Show current LLVM/package version
version:
    @python3 -c "import sys; sys.path.insert(0, 'python'); from clang import __version__; print(__version__)"

# Bump the version in README.md (run before build-and-deploy to update the version in the README for the next release)
bump-readme:
    perl -0pi -e 's/x=(\d+)/"x=" . ($1 + 1)/ge' README.md

# Create/update a local virtual environment from pyproject metadata including dev dependencies.
sync:
    uv sync --extra dev

# Run test suite.
test *args: sync
    uv run pytest -n auto {{args}}

# Build wheel with an explicit platform tag
build-wheel plat: sync
    WHEEL_PLAT_NAME={{plat}} uv build --wheel

# Download LLVM source for the current version
download-llvm:
    sh scripts/download-llvm.sh

# Update shipped libclang with patches
update-llvm: download-llvm
    sh scripts/update-python.sh

# Build libclang-ng for macOS arm64 (run download-llvm first)
build-macos-arm64 *args: update-llvm
    sh scripts/build-macos-arm64.sh
    mkdir -p build/src/clang/native/resource/include build/src/clang/native/libcxx
    cp build/llvm/cmake-build/lib/libclang.dylib build/src/clang/native/
    cp -r build/llvm/src/clang/lib/Headers/. build/src/clang/native/resource/include/
    cmake -S build/llvm/src/libcxx -B build/llvm/libcxx-config -DLLVM_DIR=build/llvm/cmake-build/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release -DLIBCXX_INCLUDE_TESTS=OFF -DLIBCXX_INCLUDE_BENCHMARKS=OFF -DLIBCXX_INCLUDE_DOCS=OFF
    cp -r build/llvm/src/libcxx/include/. build/src/clang/native/libcxx/
    cp -r build/llvm/libcxx-config/include/c++/v1/. build/src/clang/native/libcxx/
    @just build-wheel macosx_11_0_arm64
    @just test {{args}}
