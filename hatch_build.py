import os
import platform

from hatchling.builders.hooks.plugin.interface import BuildHookInterface

_EXT = {"linux": ".so", "darwin": ".dylib", "windows": ".dll"}


class CustomBuildHook(BuildHookInterface):
    PLUGIN_NAME = "custom"

    def initialize(self, version: str, build_data: dict) -> None:
        if self.target_name != "wheel":
            return

        plat_name = os.environ.get("WHEEL_PLAT_NAME")
        if plat_name:
            build_data["tag"] = f"py3-none-{plat_name}"
            build_data["pure_python"] = False
            return

        system = platform.system().lower()
        ext = _EXT.get(system)
        if not ext:
            return

        native = os.path.join("build", "src", "clang", "native", f"libclang{ext}")
        if os.path.exists(native):
            build_data["pure_python"] = False
            build_data["infer_tag"] = True
