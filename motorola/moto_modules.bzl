load("//build/kernel/kleaf:kernel.bzl", "ddk_module")

# DDK definitions of the Motorola out-of-tree modules.
#
# The Kbuild files of these modules only test make variables, none of them are
# Kconfig symbols. The variables a module is built with come from the
# KBUILD_OPTIONS of its Makefile in the LineageOS kernel_motorola_sm6475-modules
# tree. Variables that only some devices set are given per product and picked
# with --//vendor/qcom/kernel:mmi_product=<product>.

MOTO_ROOT = "//vendor/qcom/sm8450-modules/motorola"

# (target, variant) pairs to define the modules for.
MOTO_TARGET_VARIANTS = [
    ("parrot", "consolidate"),
    ("parrot", "perf"),
]

def _evaluate(conditions, variables):
    """Values of the conditions met by variables; a "!VAR" key matches when VAR is unset."""
    result = []
    for condition, values in conditions.items():
        if condition.startswith("!"):
            met = condition[1:] not in variables
        else:
            met = condition in variables
        if met:
            result += [v for v in values if v not in result]
    return result

def _resolve(conditions, make_variables, product_make_variables):
    """Static list, or a select() over the products when some variables are product specific."""
    if not conditions:
        return []
    if not product_make_variables:
        return _evaluate(conditions, make_variables)

    branches = {"//conditions:default": _evaluate(conditions, make_variables)}
    for product, variables in product_make_variables.items():
        branches["//vendor/qcom/kernel:mmi_product_{}".format(product)] = _evaluate(
            conditions,
            make_variables + variables,
        )
    return select(branches)

def moto_module(
        name,
        srcs,
        out = None,
        deps = [],
        includes = [],
        local_defines = [],
        copts = [],
        make_variables = [],
        product_make_variables = {},
        product_deps = {},
        default_product_deps = [],
        conditional_defines = {},
        conditional_srcs = {},
        conditional_copts = {},
        kernel_internal_headers = False):
    """Defines a Motorola module for every (target, variant) in MOTO_TARGET_VARIANTS.

    The module is named <target>_<variant>_<name>.

    Args:
      name: module name
      srcs: sources and private headers that are always built
      out: name of the .ko, defaults to <name>.ko
      deps: dependencies, %b is replaced with <target>_<variant>
      includes: include directories, relative to the package
      local_defines: unconditional defines
      copts: unconditional compiler options
      make_variables: make variables set for every product (Makefile KBUILD_OPTIONS)
      product_make_variables: dict of product -> additional make variables
      product_deps: dict of product -> dependencies used instead of
        default_product_deps for that product, %b is replaced as in deps
      default_product_deps: dependencies for products not in product_deps
      conditional_defines: dict of make variable -> defines (the Kbuild ifneq blocks)
      conditional_srcs: dict of make variable -> sources
      conditional_copts: dict of make variable -> compiler options
      kernel_internal_headers: whether the module includes kernel internal
        headers (kernel/sched, drivers/android, drivers/base)
    """
    common_deps = [
        "//vendor/qcom/kernel:all_headers",
        MOTO_ROOT + ":public_headers",
    ]
    if kernel_internal_headers:
        common_deps.append("//vendor/qcom/kernel:moto_kernel_internal_headers")

    for target, variant in MOTO_TARGET_VARIANTS:
        tv = "{}_{}".format(target, variant)

        module_deps = common_deps + [dep.replace("%b", tv) for dep in deps]
        if product_deps:
            branches = {"//conditions:default": [dep.replace("%b", tv) for dep in default_product_deps]}
            for product, product_dep_list in product_deps.items():
                branches["//vendor/qcom/kernel:mmi_product_{}".format(product)] = [
                    dep.replace("%b", tv)
                    for dep in product_dep_list
                ]
            module_deps = module_deps + select(branches)
        elif default_product_deps:
            module_deps = module_deps + [dep.replace("%b", tv) for dep in default_product_deps]

        ddk_module(
            name = "{}_{}".format(tv, name),
            out = out or "{}.ko".format(name),
            srcs = srcs + _resolve(conditional_srcs, make_variables, product_make_variables),
            includes = includes,
            local_defines = local_defines + _resolve(conditional_defines, make_variables, product_make_variables),
            copts = copts + _resolve(conditional_copts, make_variables, product_make_variables),
            deps = module_deps,
            kernel_build = "//vendor/qcom/kernel:{}".format(tv),
            visibility = ["//visibility:public"],
        )
