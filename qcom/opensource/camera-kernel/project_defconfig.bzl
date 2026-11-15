load("@bazel_skylib//rules:write_file.bzl", "write_file")

common_configs = [
	"CONFIG_SPECTRA_ISP=y",
	"CONFIG_SPECTRA_ICP=y",
	"CONFIG_SPECTRA_SENSOR=y",
]

project_configs = {
	"parrot": [
		"CONFIG_SPECTRA_TFE=y",
		"CONFIG_SPECTRA_CRE=y",
	],
    "waipio": [
		"CONFIG_SPECTRA_JPEG=y",
		"CONFIG_SPECTRA_CUSTOM=y",
		"CONFIG_INTERCONNECT_QCOM=y",
		"CONFIG_MSM_MMRM=y",
		"CONFIG_MSM_GLOBAL_SYNX=y",
	],
}

"""
Return a label which defines a project-specific defconfig snippet to be
applied on top of the platform defconfig.
"""

def get_project_defconfig(target, variant):
    rule_name = "{}_{}_project_defconfig".format(target, variant)

    write_file(
        name = rule_name,
        out = "{}.generated".format(rule_name),
        content = common_configs + project_configs.get(target, []) + [""],
    )

    return rule_name
