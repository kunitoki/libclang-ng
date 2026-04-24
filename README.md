![Backdrop](https://raw.githubusercontent.com/kunitoki/libclang-ng/main/backdrop.jpg?x=2)

[![PyPI](https://img.shields.io/pypi/v/libclang-ng?x=2)](https://pypi.org/project/libclang-ng)
[![Python](https://img.shields.io/pypi/pyversions/libclang-ng?x=2)](https://pypi.org/project/libclang-ng)
[![Downloads](https://img.shields.io/pypi/dw/libclang-ng?x=2)](https://pypistats.org/packages/libclang-ng)
[![License](https://img.shields.io/pypi/l/libclang-ng?x=2)](https://github.com/kunitoki/libclang-ng/blob/master/LICENSE)
[![Arch: x64](https://img.shields.io/badge/arch-x86__64-brightgreen?x=2)](https://pypi.org/project/libclang-ng/#files)
[![Arch: aarch64](https://img.shields.io/badge/arch-aarch64-yellowgreen?x=2)](https://pypi.org/project/libclang-ng/#files)

[![Linux x64](https://github.com/kunitoki/libclang-ng/workflows/linux-amd64/badge.svg?x=2)](https://github.com/kunitoki/libclang-ng/actions/workflows/linux-amd64.yml)
[![Linux Arm64](https://github.com/kunitoki/libclang-ng/workflows/linux-aarch64/badge.svg?x=2)](https://github.com/kunitoki/libclang-ng/actions/workflows/linux-aarch64.yml)
[![MacOS x64](https://github.com/kunitoki/libclang-ng/workflows/macos-amd64/badge.svg?x=2)](https://github.com/kunitoki/libclang-ng/actions/workflows/macos-amd64.yml)
[![MacOS Arm64](https://github.com/kunitoki/libclang-ng/workflows/macos-arm64/badge.svg?x=2)](https://github.com/kunitoki/libclang-ng/actions/workflows/macos-arm64.yml)
[![Windows x64](https://github.com/kunitoki/libclang-ng/workflows/windows-amd64/badge.svg?x=2)](https://github.com/kunitoki/libclang-ng/actions/workflows/windows-amd64.yml)
[![Windows Arm64](https://github.com/kunitoki/libclang-ng/workflows/windows-aarch64/badge.svg?x=2)](https://github.com/kunitoki/libclang-ng/actions/workflows/windows-aarch64.yml)

# libclang-ng

`libclang-ng` packages the official [Clang Python Bindings][1] (`clang.cindex`) from the LLVM project and bundles a statically-linked `libclang` shared library for each supported platform. The result is a zero-configuration `pip install` that gives you a working Clang Python API without installing the LLVM toolchain.

> **Note:** This package is named `libclang-ng`, and it's the natural evolution of `libclang`. The `clang` package on PyPI is a separate project and does not bundle a prebuilt shared library.

Installation
------------

Install using **pip**:
```bash
pip install libclang-ng==20.1.8.1
```

Install using **uv**:
```bash
uv pip install libclang-ng==20.1.8.1
```

Best way to specify pinning is to allow for patch updates on the same clang version:

```bash
pip install "libclang-ng>=20.1.8.0,<21.0.0.0" --upgrade
```

Requirements
------------

- Python **3.12** or later

Platform Support
----------------

| Platform | Architecture | Minimum OS |
|----------|-------------|------------|
| Linux    | x86_64      | glibc 2.28+ (manylinux_2_28) |
| Linux    | aarch64     | glibc 2.28+ (manylinux_2_28) |
| macOS    | x86_64      | 10.9+ |
| macOS    | arm64       | 11.0+ |
| Windows  | x86_64      | — |
| Windows  | arm64       | — |

All native libraries are statically linked and libcxx headers are bundled in the python package - there are no external runtime dependencies beyond the standard system libraries (glibc on Linux, system frameworks on macOS, MSVC runtime on Windows).

Clang Versions
--------------

Supported clang versions:

- 19.1.7 ([https://github.com/llvm/llvm-project/releases/tag/llvmorg-19.1.7](https://github.com/llvm/llvm-project/releases/tag/llvmorg-19.1.7))
- 20.1.8 ([https://github.com/llvm/llvm-project/releases/tag/llvmorg-20.1.8](https://github.com/llvm/llvm-project/releases/tag/llvmorg-20.1.8))
- 21.1.8 ([https://github.com/llvm/llvm-project/releases/tag/llvmorg-21.1.8](https://github.com/llvm/llvm-project/releases/tag/llvmorg-21.1.8))
- 22.1.4 ([https://github.com/llvm/llvm-project/releases/tag/llvmorg-22.1.4](https://github.com/llvm/llvm-project/releases/tag/llvmorg-22.1.4))

Quick Start
-----------

### Parse a file and walk the AST

```python
from clang.cindex import Index, CursorKind

index = Index.create()
tu = index.parse("example.cpp", args=["-std=c++17"])

for cursor in tu.cursor.get_children():
    if cursor.kind == CursorKind.FUNCTION_DECL:
        print(f"Function: {cursor.spelling} at {cursor.location}")
        for param in cursor.get_arguments():
            print(f"  param: {param.spelling} ({param.type.spelling})")
```

### Parse from a string (in-memory)

```python
from clang.cindex import Index

index = Index.create()
tu = index.parse(
    "example.cpp",
    unsaved_files=[("example.cpp", "int add(int a, int b) { return a + b; }")],
    args=["-std=c++17"],
)

for cursor in tu.cursor.walk_preorder():
    print(f"{cursor.kind.name}: {cursor.spelling}")
```

### Collect diagnostics

```python
from clang.cindex import Index, Diagnostic

index = Index.create()
tu = index.parse("example.cpp")

for diag in tu.diagnostics:
    if diag.severity >= Diagnostic.Warning:
        print(f"{diag.severity}: {diag.spelling} [{diag.location}]")
```

### Type introspection

```python
from clang.cindex import Index, CursorKind, TypeKind

index = Index.create()
tu = index.parse("example.cpp")

for cursor in tu.cursor.walk_preorder():
    if cursor.kind == CursorKind.STRUCT_DECL:
        t = cursor.type
        print(f"struct {cursor.spelling}: size={t.get_size()} bytes")
        for field in t.get_fields():
            print(f"  {field.spelling}: {field.type.spelling} offset={t.get_offset(field.spelling)} bits")
```

### Use a compilation database

```python
from clang.cindex import Index, CompilationDatabase

db = CompilationDatabase.from_directory("/path/to/build")
cmds = db.get_compile_commands("src/main.cpp")

index = Index.create()
for cmd in cmds:
    tu = index.parse(cmd.filename, args=list(cmd.arguments)[1:])
```

API Overview
------------

| Class | Purpose |
|-------|---------|
| `Index` | Entry point — creates and owns translation units |
| `TranslationUnit` | Represents a parsed source file; holds cursors and diagnostics |
| `Cursor` | A node in the AST (declaration, expression, statement, …) |
| `CursorKind` | Enumeration of all cursor node types |
| `Type` | Type information attached to a cursor |
| `TypeKind` | Enumeration of all type kinds |
| `Diagnostic` | A compiler warning or error with location and fix-it hints |
| `Token` | A lexical token (keyword, identifier, literal, …) |
| `SourceLocation` | File/line/column position in source |
| `SourceRange` | Start and end `SourceLocation` pair |
| `CompilationDatabase` | Reads `compile_commands.json` for project-wide parsing |

Full API documentation is generated from the module docstrings via Sphinx and is available at [libclang-ng.readthedocs.io][3].

Configuration
-------------

By default the package locates `libclang` automatically from its bundled `native/` directory. Override this when you want to use a system-installed or custom-built library:

**Environment variable (before importing `clang`):**
```bash
export LIBCLANG_LIBRARY_PATH=/usr/lib/llvm-19/lib
python your_script.py
```

**Programmatic override (before any other `clang` import):**
```python
from clang.cindex import Config
Config.set_library_path("/usr/lib/llvm-19/lib")
# or point to a specific file:
# Config.set_library_file("/usr/lib/llvm-19/lib/libclang.so.19")
```

Development
-----------

The repository uses [`just`][4] as a task runner and [`uv`][5] as the Python package manager.

```bash
# Show the current LLVM version
just version

# Download LLVM source and update Python bindings
just download-llvm

# Full local build for macOS ARM64
just build-macos-arm64
```

### CI / Release

Six GitHub Actions workflows build and publish a platform-specific wheel for each supported target. A release is triggered by pushing a version tag (`v*`), which causes each workflow to publish its wheel to PyPI.

License
-------

This repository follows the license of the LLVM project: [Apache-2.0 WITH LLVM-exception](./LICENSE.TXT).

[1]: https://github.com/llvm/llvm-project/tree/main/clang/bindings/python
[2]: https://pypi.org/project/libclang-ng
[3]: https://libclang-ng.readthedocs.io
[4]: https://just.systems
[5]: https://docs.astral.sh/uv
