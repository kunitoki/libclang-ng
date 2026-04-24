$ErrorActionPreference = "Stop"

$TOP_DIR = (Get-Item "$PSScriptRoot\..").FullName
Set-Location $TOP_DIR

$BUILD_DIR = "$TOP_DIR\build\llvm\cmake-build"
$HOST_BUILD_DIR = "$TOP_DIR\build\llvm\cmake-build-host"

New-Item -ItemType Directory -Force -Path $BUILD_DIR | Out-Null
New-Item -ItemType Directory -Force -Path $HOST_BUILD_DIR | Out-Null

if (Test-Path "$BUILD_DIR\Release\bin\libclang.dll") {
    Write-Host "libclang.dll already built, skipping build"
    exit 0
}

$CPUS = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors

# Build host tblgen tools (x64) needed for cross-compilation
Set-Location $HOST_BUILD_DIR

cmake "$TOP_DIR\build\llvm\src\llvm" `
    -Thost=x64 `
    -DLLVM_ENABLE_PROJECTS=clang `
    -DBUILD_SHARED_LIBS=OFF `
    -DLLVM_ENABLE_ZLIB=OFF `
    -DLLVM_ENABLE_ZSTD=OFF `
    -DLLVM_ENABLE_TERMINFO=OFF `
    -DLLVM_INCLUDE_TESTS=OFF `
    -DLLVM_INCLUDE_DOCS=OFF `
    -DCLANG_INCLUDE_TESTS=OFF `
    -DCLANG_INCLUDE_DOCS=OFF `
    -DLLVM_TARGETS_TO_BUILD=X86 `
    -DLLVM_USE_CRT_RELEASE=MT `
    "-DCMAKE_C_COMPILER_LAUNCHER=sccache" `
    "-DCMAKE_CXX_COMPILER_LAUNCHER=sccache"

cmake --build . --config Release --target llvm-tblgen -j $CPUS
cmake --build . --config Release --target clang-tblgen -j $CPUS

# Cross-compile libclang for ARM64
Set-Location $BUILD_DIR

cmake "$TOP_DIR\build\llvm\src\llvm" `
    -A ARM64 `
    -Thost=x64 `
    -DLLVM_ENABLE_PROJECTS=clang `
    -DBUILD_SHARED_LIBS=OFF `
    -DLLVM_ENABLE_ZLIB=OFF `
    -DLLVM_ENABLE_ZSTD=OFF `
    -DLLVM_ENABLE_TERMINFO=OFF `
    -DLLVM_INCLUDE_TESTS=OFF `
    -DLLVM_INCLUDE_DOCS=OFF `
    -DCLANG_INCLUDE_TESTS=OFF `
    -DCLANG_INCLUDE_DOCS=OFF `
    -DLLVM_TARGETS_TO_BUILD=AArch64 `
    "-DLLVM_TABLEGEN=$HOST_BUILD_DIR\Release\bin\llvm-tblgen.exe" `
    "-DCLANG_TABLEGEN=$HOST_BUILD_DIR\Release\bin\clang-tblgen.exe" `
    -DLLVM_USE_CRT_RELEASE=MT `
    "-DCMAKE_C_COMPILER_LAUNCHER=sccache" `
    "-DCMAKE_CXX_COMPILER_LAUNCHER=sccache"

cmake --build . --config Release --target libclang -j $CPUS

Write-Host ""
Write-Host "=== build output ==="
Get-Item "$BUILD_DIR\Release\bin\libclang.dll" | Select-Object FullName, Length
