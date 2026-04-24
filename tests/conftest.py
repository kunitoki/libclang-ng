import sys
import os

# When running from repo root (locally or CI pre-install), inject build/src so
# `import clang` resolves to the locally-built package.  When the wheel is
# already installed the import succeeds without this and the insert is a no-op.
_build_src = os.path.join(os.path.dirname(__file__), "..", "build", "src")
_build_src = os.path.normpath(_build_src)
if os.path.isdir(_build_src):
    sys.path.insert(0, _build_src)
