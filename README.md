libclang-ng
===========

[![PyPI](https://img.shields.io/pypi/v/libclang-ng)](https://pypi.org/project/libclang-ng)
![Python](https://img.shields.io/pypi/pyversions/libclang-ng)
![Downloads](https://img.shields.io/pypi/dw/libclang-ng)
[![License](https://img.shields.io/pypi/l/libclang-ng)](https://github.com/kunitoki/libclang-ng/blob/master/LICENSE.TXT)

[![Arch: x86\_64](https://img.shields.io/badge/arch-x86__64-brightgreen)](https://pypi.org/project/libclang-ng/#files)
[![Arch: aarch64](https://img.shields.io/badge/arch-aarch64-yellowgreen)](https://pypi.org/project/libclang-ng/#files)
[![Arch: arm](https://img.shields.io/badge/arch-arm-orange)](https://pypi.org/project/libclang-ng/#files)

[![Linux](https://github.com/kunitoki/libclang-ng/workflows/build-linux-amd64/badge.svg)](https://github.com/kunitoki/libclang-ng/actions/workflows/build-linux-amd64.yml)
[![Linux Arm](https://github.com/kunitoki/libclang-ng/workflows/build-linux-arm/badge.svg)](https://github.com/kunitoki/libclang-ng/actions/workflows/build-linux-arm.yml)
[![Linux AArch64](https://github.com/kunitoki/libclang-ng/workflows/build-linux-aarch64/badge.svg)](https://github.com/kunitoki/libclang-ng/actions/workflows/build-linux-aarch64.yml)
[![Linux Alpine](https://github.com/kunitoki/libclang-ng/workflows/build-alpine-amd64/badge.svg)](https://github.com/kunitoki/libclang-ng/actions/workflows/build-alpine-amd64.yml)

[![MacOS Intel](https://github.com/kunitoki/libclang-ng/workflows/build-macosx-amd64/badge.svg)](https://github.com/kunitoki/libclang-ng/actions/workflows/build-macosx-amd64.yml)
[![MacOS M1](https://img.shields.io/cirrus/github/kunitoki/libclang-ng?label=build-macosx-arm64)](https://cirrus-ci.com/github/kunitoki/libclang-ng)

[![Windows](https://github.com/kunitoki/libclang-ng/workflows/build-windows-amd64/badge.svg)](https://github.com/kunitoki/libclang-ng/actions/workflows/build-windows-amd64.yml)
[![Windows AArch64](https://github.com/kunitoki/libclang-ng/workflows/build-windows-aarch64/badge.svg)](https://github.com/kunitoki/libclang-ng/actions/workflows/build-windows-aarch64.yml)

The repository contains code taken from [the LLVM project][1], to make it easier to install clang's python bindings.

The repository copies necessary Python binding files from LLVM repo, adds packaging scripts to make it a valid Python package and finally uploads the package to [pypi][2]. To make the libclang-ng available without installing the LLVM toolkits, this package provides bundled static-linked libclang-ng shared library for different platforms, which, should work well on OSX, Windows, as well as usual Linux distributions.

The aim of this project is to make the `clang.cindex` (aka., Clang Python Bindings) available for more Python users, without setting up the LLVM environment. To install the package, you just need to run

```bash
pip install libclang-ng
```

Note that the library is named `libclang-ng`, the package `clang` on PyPi is another package and doesn't bundle the prebuilt shared library.

License
-------

This repository follows the license agreement of the LLVM project, see [Apache-2.0 WITH LLVM-exception](./LICENSE.TXT).

[1]: https://github.com/llvm/llvm-project/tree/main/clang/bindings/python
[2]: https://pypi.org/project/libclang-ng
