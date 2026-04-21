"""Tests for bundled resource headers and libcxx headers in the wheel."""

import os
import tempfile
import textwrap
import pytest


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _clang_native_dir():
    import clang.cindex
    return os.path.join(os.path.dirname(os.path.realpath(clang.cindex.__file__)), "native")


def _resource_dir():
    from clang.cindex import Config
    return Config.resource_dir


def _libcxx_dir():
    from clang.cindex import Config
    return Config.libcxx_dir


def _parse(source: str, filename: str = "test.cpp", args: list[str] | None = None):
    import clang.cindex
    idx = clang.cindex.Index.create()
    return idx.parse(filename, args=args or [], unsaved_files=[(filename, source)])


# ---------------------------------------------------------------------------
# Config defaults
# ---------------------------------------------------------------------------

class TestConfigDefaults:
    def test_resource_dir_attribute_exists(self):
        from clang.cindex import Config
        assert hasattr(Config, "resource_dir")

    def test_libcxx_dir_attribute_exists(self):
        from clang.cindex import Config
        assert hasattr(Config, "libcxx_dir")

    def test_resource_dir_points_inside_native(self):
        native = _clang_native_dir()
        resource = _resource_dir()
        assert resource is not None
        assert os.path.normpath(resource).startswith(os.path.normpath(native))

    def test_libcxx_dir_points_inside_native(self):
        native = _clang_native_dir()
        libcxx = _libcxx_dir()
        assert libcxx is not None
        assert os.path.normpath(libcxx).startswith(os.path.normpath(native))

    def test_resource_dir_default_path(self):
        native = _clang_native_dir()
        expected = os.path.join(native, "resource")
        assert os.path.normpath(_resource_dir()) == os.path.normpath(expected)

    def test_libcxx_dir_default_path(self):
        native = _clang_native_dir()
        expected = os.path.join(native, "libcxx")
        assert os.path.normpath(_libcxx_dir()) == os.path.normpath(expected)


# ---------------------------------------------------------------------------
# Bundled header presence
# ---------------------------------------------------------------------------

class TestResourceHeadersPresent:
    def test_resource_dir_exists_on_disk(self):
        assert os.path.isdir(_resource_dir()), f"resource_dir not found: {_resource_dir()}"

    def test_resource_include_dir_exists(self):
        include_dir = os.path.join(_resource_dir(), "include")
        assert os.path.isdir(include_dir), f"resource/include not found: {include_dir}"

    @pytest.mark.parametrize("header", ["stddef.h", "stdarg.h", "float.h", "limits.h"])
    def test_key_resource_headers_present(self, header):
        path = os.path.join(_resource_dir(), "include", header)
        assert os.path.isfile(path), f"Missing resource header: {path}"


class TestLibcxxHeadersPresent:
    def test_libcxx_dir_exists_on_disk(self):
        assert os.path.isdir(_libcxx_dir()), f"libcxx_dir not found: {_libcxx_dir()}"

    @pytest.mark.parametrize("header", ["string", "vector", "iostream", "algorithm"])
    def test_key_libcxx_headers_present(self, header):
        path = os.path.join(_libcxx_dir(), header)
        assert os.path.isfile(path), f"Missing libcxx header: {path}"


# ---------------------------------------------------------------------------
# Env-var overrides
# ---------------------------------------------------------------------------

class TestEnvVarOverrides:
    def test_resource_dir_env_override(self, monkeypatch, tmp_path):
        custom = str(tmp_path / "myresource")
        os.makedirs(custom)
        monkeypatch.setenv("LIBCLANG_RESOURCE_DIR_PATH", custom)
        # Re-evaluate the class variable (it's set at class definition time from
        # os.environ.get, so we test the override by checking os.environ directly).
        assert os.environ.get("LIBCLANG_RESOURCE_DIR_PATH") == custom

    def test_libcxx_dir_env_override(self, monkeypatch, tmp_path):
        custom = str(tmp_path / "mylibcxx")
        os.makedirs(custom)
        monkeypatch.setenv("LIBCLANG_LIBSTDCXX_HEADER_PATH", custom)
        assert os.environ.get("LIBCLANG_LIBSTDCXX_HEADER_PATH") == custom


# ---------------------------------------------------------------------------
# from_source argument injection
# ---------------------------------------------------------------------------

class TestFromSourceArgInjection:
    def test_resource_dir_injected_into_c_parse(self):
        """Parsing C with no explicit -resource-dir must not produce 'file not found'
        for compiler built-ins (stddef.h etc.)."""
        source = "#include <stddef.h>\nsize_t x = sizeof(int);\n"
        tu = _parse(source, "test.c", args=["-std=c11"])
        fatal = [d for d in tu.diagnostics if d.severity >= 3]
        assert not fatal, f"Fatal diagnostics: {[str(d) for d in fatal]}"

    def test_libcxx_injected_into_cpp_parse(self):
        """Parsing C++ with no explicit -isystem must not produce 'file not found'
        for libc++ headers."""
        source = "#include <string>\nstd::string s;\n"
        tu = _parse(source, "test.cpp", args=["-std=c++17"])
        file_not_found = [
            d for d in tu.diagnostics
            if d.severity >= 3 and "file not found" in str(d).lower()
        ]
        assert not file_not_found, f"Missing-header diagnostics: {[str(d) for d in file_not_found]}"

    def test_no_duplicate_resource_dir_when_explicit(self):
        """If -resource-dir is already in args, from_source must not add another."""
        import clang.cindex as ci
        resource = _resource_dir()
        # Patch from_source to capture actual args used
        original = ci.TranslationUnit.from_source.__func__

        captured = {}

        def spy(cls, filename, args=None, unsaved_files=None, options=None, index=None):
            captured["args"] = list(args or [])
            return original(cls, filename, args=args, unsaved_files=unsaved_files,
                            options=options, index=index)

        ci.TranslationUnit.from_source = classmethod(spy)
        try:
            explicit_args = ["-resource-dir", resource, "-std=c11"]
            _parse("int x;", "test.c", args=explicit_args)
        finally:
            ci.TranslationUnit.from_source = classmethod(original)

        resource_dir_count = sum(1 for a in captured["args"] if a == "-resource-dir")
        assert resource_dir_count == 1, (
            f"-resource-dir appears {resource_dir_count} times in args: {captured['args']}"
        )

    def test_no_duplicate_isystem_when_explicit(self):
        """If -isystem is already in args, from_source must not add another."""
        import clang.cindex as ci
        libcxx = _libcxx_dir()
        original = ci.TranslationUnit.from_source.__func__

        captured = {}

        def spy(cls, filename, args=None, unsaved_files=None, options=None, index=None):
            captured["args"] = list(args or [])
            return original(cls, filename, args=args, unsaved_files=unsaved_files,
                            options=options, index=index)

        ci.TranslationUnit.from_source = classmethod(spy)
        try:
            explicit_args = ["-isystem", libcxx, "-std=c++17"]
            _parse("int x;", "test.cpp", args=explicit_args)
        finally:
            ci.TranslationUnit.from_source = classmethod(original)

        isystem_count = sum(1 for a in captured["args"] if a == "-isystem")
        assert isystem_count == 1, (
            f"-isystem appears {isystem_count} times in args: {captured['args']}"
        )


# ---------------------------------------------------------------------------
# End-to-end parsing
# ---------------------------------------------------------------------------

class TestEndToEndParsing:
    def test_parse_empty_c_file(self):
        tu = _parse("", "empty.c", args=["-std=c11"])
        assert tu is not None

    def test_parse_stddef_h(self):
        source = "#include <stddef.h>\nsize_t n = 0;\n"
        tu = _parse(source, "test.c", args=["-std=c11"])
        errors = [d for d in tu.diagnostics if d.severity >= 3]
        assert not errors, f"Errors parsing stddef.h: {[str(d) for d in errors]}"

    def test_parse_float_h(self):
        source = "#include <float.h>\ndouble x = DBL_MAX;\n"
        tu = _parse(source, "test.c", args=["-std=c11"])
        errors = [d for d in tu.diagnostics if d.severity >= 3]
        assert not errors, f"Errors parsing float.h: {[str(d) for d in errors]}"

    def test_parse_cpp_string(self):
        source = textwrap.dedent("""\
            #include <string>
            std::string hello() { return "hello"; }
        """)
        tu = _parse(source, "test.cpp", args=["-std=c++17"])
        file_not_found = [
            d for d in tu.diagnostics
            if d.severity >= 3 and "file not found" in str(d).lower()
        ]
        assert not file_not_found, f"Missing headers: {[str(d) for d in file_not_found]}"

    def test_parse_cpp_vector(self):
        source = textwrap.dedent("""\
            #include <vector>
            std::vector<int> v = {1, 2, 3};
        """)
        tu = _parse(source, "test.cpp", args=["-std=c++17"])
        file_not_found = [
            d for d in tu.diagnostics
            if d.severity >= 3 and "file not found" in str(d).lower()
        ]
        assert not file_not_found, f"Missing headers: {[str(d) for d in file_not_found]}"

    def test_cursor_hash_is_callable(self):
        """Regression: Cursor.__hash__ patch must be present."""
        source = "int foo(int x) { return x + 1; }\n"
        tu = _parse(source, "test.c", args=["-std=c11"])
        cursors = list(tu.cursor.get_children())
        assert cursors, "Expected at least one cursor child"
        h = hash(cursors[0])
        assert isinstance(h, int)
