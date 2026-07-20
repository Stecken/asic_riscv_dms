# Canonical project metadata consumed by Make and the ChipInventor tooling.
PROJECT_NAME := asic_riscv_dms
TOP_MODULE := riscv_top
RTL_MANIFEST := rtl/files.f

PORTABLE_TB_TOP := tb_core
PORTABLE_TB_SOURCE := tb/portable/tb_core.v
PORTABLE_UNIT_DIR := tb/portable/unit

FIRMWARE_DIR := tb/support/firmware
DEFAULT_FIRMWARE := core_basic.hex
PACKAGE_FIRMWARE_FILES := core_basic.hex

WAVEFORM_DIR := waves
CHIPINVENTOR_DIST_DIR := dist/chipinventor
CHIPINVENTOR_RELEASE_DIR := dist/releases
CHIPINVENTOR_PACKAGE_FORMAT_VERSION := 1
CHIPINVENTOR_LANGUAGE_PROFILE := systemverilog-2012
CHIPINVENTOR_CONFIG_TEMPLATE := config/chipinventor.config.template.json
