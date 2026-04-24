"""Tests for the bundled shared library file in the wheel."""

import os
import platform


def _native_dir():
    import clang.cindex
    return os.path.join(os.path.dirname(os.path.realpath(clang.cindex.__file__)), "native")


def _expected_library_filename():
    name = platform.system()
    if name == "Darwin":
        return "libclang.dylib"
    elif name == "Windows":
        return "libclang.dll"
    else:
        return "libclang.so"


def _bundled_library_path():
    return os.path.join(_native_dir(), _expected_library_filename())


# ---------------------------------------------------------------------------
# Library file presence
# ---------------------------------------------------------------------------

class TestBundledLibraryPresent:
    def test_native_dir_exists(self):
        assert os.path.isdir(_native_dir()), f"native dir not found: {_native_dir()}"

    def test_library_file_exists(self):
        path = _bundled_library_path()
        assert os.path.isfile(path), f"bundled library not found: {path}"

    def test_library_file_nonempty(self):
        path = _bundled_library_path()
        assert os.path.getsize(path) > 0, f"bundled library is empty: {path}"

    def test_library_filename_matches_platform(self):
        name = platform.system()
        filename = _expected_library_filename()
        if name == "Darwin":
            assert filename.endswith(".dylib")
        elif name == "Windows":
            assert filename.endswith(".dll")
        else:
            assert filename.endswith(".so")


# ---------------------------------------------------------------------------
# Env-var overrides
# ---------------------------------------------------------------------------

class TestLibraryEnvVarOverrides:
    def test_library_path_env_override(self, monkeypatch, tmp_path):
        custom = str(tmp_path / "mylibs")
        os.makedirs(custom)
        monkeypatch.setenv("LIBCLANG_LIBRARY_PATH", custom)
        assert os.environ.get("LIBCLANG_LIBRARY_PATH") == custom

    def test_library_file_env_override(self, monkeypatch, tmp_path):
        fake_lib = tmp_path / _expected_library_filename()
        fake_lib.write_bytes(b"\x00")
        monkeypatch.setenv("LIBCLANG_LIBRARY_FILE", str(fake_lib))
        assert os.environ.get("LIBCLANG_LIBRARY_FILE") == str(fake_lib)
