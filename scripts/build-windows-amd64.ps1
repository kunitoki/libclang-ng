$ErrorActionPreference = "Stop"

$TOP_DIR = (Get-Item "$PSScriptRoot\..").FullName
Set-Location $TOP_DIR

$BUILD_DIR = "$TOP_DIR\build\llvm\cmake-build"

New-Item -ItemType Directory -Force -Path $BUILD_DIR | Out-Null
Set-Location $BUILD_DIR

if (Test-Path "Release\bin\libclang.dll") {
    Write-Host "libclang.dll already built, skipping build"
    exit 0
}

$CPUS = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors

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

cmake --build . --config Release --target libclang -j $CPUS

Write-Host ""
Write-Host "=== build output ==="
Get-Item "Release\bin\libclang.dll" | Select-Object FullName, Length
