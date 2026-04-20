default:
    @just --list

# Show current LLVM/package version
version:
    @python3 -c "import sys; sys.path.insert(0, 'python'); from clang import __version__; print(__version__)"

# Bump the version in README.md (run before build-and-deploy to update the version in the README for the next release)
bump-readme:
    perl -0pi -e 's/x=(\d+)/"x=" . ($1 + 1)/ge' README.md

# Build wheel with an explicit platform tag
build-wheel plat:
    WHEEL_PLAT_NAME={{plat}} uv build --wheel

# Download LLVM source for the current version
download-llvm:
    sh scripts/download-llvm.sh

# Build libclang-ng for macOS arm64 (run download-llvm first)
build-macos-arm64: download-llvm
    sh scripts/update-python.sh
    sh scripts/build-macos-arm64.sh
    cp build/llvm/cmake-build/lib/libclang.dylib build/src/clang/native/
    @just build-wheel macosx_11_0_arm64
