load(":synx_modules.bzl", "synx_modules")
load(":synx_module_build.bzl", "define_consolidate_perf_modules")

def define_parrot():
    define_consolidate_perf_modules(
        target = "parrot",
        registry = synx_modules,
        modules = [
            "synx-driver",
            "ipclite",
            "ipclite_test",
        ],
        config_options = [
            "TARGET_SYNX_ENABLE",
        ],
    )
