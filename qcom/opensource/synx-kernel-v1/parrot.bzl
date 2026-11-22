load(":synx_modules.bzl", "synx_modules")
load(":synx_module_build.bzl", "define_consolidate_perf_modules")

def define_parrot():
    define_consolidate_perf_modules(
        target = "parrot",
        registry = synx_modules,
        modules = [
            "qcom_ipc_lite",
            "synx-driver",
        ],
        config_options = [
            "CONFIG_MSM_GLOBAL_SYNX",
            "TARGET_SYNX_ENABLE",
        ],
    )
