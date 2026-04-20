import os
import platform

from hatchling.builders.hooks.plugin.interface import BuildHookInterface

_EXT = {"linux": ".so", "darwin": ".dylib", "windows": ".dll"}


class CustomBuildHook(BuildHookInterface):
    PLUGIN_NAME = "custom"

    def initialize(self, version: str, build_data: dict) -> None:
        if self.target_name != "wheel":
            return

        system = platform.system().lower()
        ext = _EXT.get(system)
        if not ext:
            return

        lib_name = f"libclang{ext}"
        build_src = os.path.join("build", "src", "clang")

        if not os.path.exists(build_src):
            return

        # Merged build source present: force-include all its files,
        # overriding the python/clang/ entries from pyproject.toml packages.
        for dirpath, dirnames, filenames in os.walk(build_src):
            dirnames[:] = [d for d in dirnames if d != "__pycache__"]
            for fname in filenames:
                if fname.endswith(".pyc"):
                    continue
                src = os.path.join(dirpath, fname)
                rel = os.path.relpath(src, build_src).replace(os.sep, "/")
                build_data["force_include"][src] = f"clang/{rel}"

        native = os.path.join(build_src, "native", lib_name)
        if not os.path.exists(native):
            return  # no native lib — pure-Python build

        plat_name = os.environ.get("WHEEL_PLAT_NAME")
        if plat_name:
            build_data["tag"] = f"py3-none-{plat_name}"
        else:
            build_data["pure_python"] = False
            build_data["infer_tag"] = True
