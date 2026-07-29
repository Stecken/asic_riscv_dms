SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

include config/project.mk

TEST ?= core_basic
MODULE ?= alu

RTL_SOURCES := $(shell sed -e '/^[[:space:]]*\#/d' -e '/^[[:space:]]*$$/d' $(RTL_MANIFEST))
UNIT_TESTS := alu register_file imem dmem immediate_gen branch_comp control lui auipc jalr
PROGRAM_HEX := $(FIRMWARE_DIR)/$(TEST).hex
PROGRAM_WORDS := $(shell if test -f "$(PROGRAM_HEX)"; then wc -l < "$(PROGRAM_HEX)"; else echo 0; fi)
CORE_BINARY := build/sim/$(TEST)/$(PORTABLE_TB_TOP).vvp
CORE_LOG := build/logs/test-core-$(TEST).log
CORE_TEST_WAVE := build/sim/$(TEST)/test-core.vcd
WAVE_FILE := $(WAVEFORM_DIR)/$(TEST).vcd
LEGACY_DIR := legacy/original-export/design2.0-2026.06.21/design

IVERILOG_FLAGS := -g2012 -Wall -Wimplicit
VERILATOR_FLAGS := --lint-only --top-module $(TOP_MODULE) -Wall

.PHONY: help setup-check lint build test test-unit test-core test-legacy wave open-wave \
	programs programs-check synth schematic clean ci dirs chipinventor-portability \
	chipinventor-package chipinventor-check chipinventor-release \
	chipinventor-validation-record chipinventor-status openlane-readiness

help: ## Show the supported commands.
	@awk 'BEGIN {FS = ":.*## "; print "RISC-V HDL laboratory targets:"} /^[a-zA-Z0-9_-]+:.*## / {printf "  %-18s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

dirs:
	@mkdir -p build/rtl build/sim build/logs build/synth build/schematic reports waves

setup-check: ## Verify tools, versions, and the official source manifest.
	@bash scripts/setup-check.sh

lint: dirs ## Lint every official RTL source with manifest checks, Icarus, and Verilator.
	@python3 scripts/check_sources.py | tee build/logs/source-check.log
	@set -o pipefail; iverilog $(IVERILOG_FLAGS) -s $(TOP_MODULE) -o build/rtl/$(TOP_MODULE)-lint.vvp $(RTL_SOURCES) 2>&1 | tee build/logs/iverilog-lint.log
	@set -o pipefail; verilator $(VERILATOR_FLAGS) $(RTL_SOURCES) 2>&1 | tee build/logs/verilator-lint.log

build: dirs ## Compile the official RTL top with Icarus Verilog.
	@set -o pipefail; iverilog $(IVERILOG_FLAGS) -s $(TOP_MODULE) -o build/rtl/$(TOP_MODULE).vvp $(RTL_SOURCES) 2>&1 | tee build/logs/build.log
	@echo "Build: build/rtl/$(TOP_MODULE).vvp"

programs: ## Regenerate checked-in .hex programs with the minimal assembler.
	@for source in $(FIRMWARE_DIR)/*.S; do \
		output="$${source%.S}.hex"; \
		python3 scripts/assemble_test_program.py "$$source" "$$output"; \
		echo "Generated $$output"; \
	done

programs-check: ## Confirm that every checked-in .hex matches its Assembly source.
	@for source in $(FIRMWARE_DIR)/*.S; do \
		output="$${source%.S}.hex"; \
		python3 scripts/assemble_test_program.py --check "$$source" "$$output"; \
	done
	@echo "PASS programs-check"

test-unit: dirs ## Run all self-checking unit tests.
	@set -euo pipefail; \
	for test_name in $(UNIT_TESTS); do \
		binary="build/sim/tb_$${test_name}.vvp"; \
		log="build/logs/test-unit-$${test_name}.log"; \
		iverilog $(IVERILOG_FLAGS) -DRISCV_DEBUG -s "tb_$${test_name}" -o "$$binary" $(RTL_SOURCES) "$(PORTABLE_UNIT_DIR)/tb_$${test_name}.v" 2>&1 | tee "$$log"; \
		vvp "$$binary" 2>&1 | tee -a "$$log"; \
	done

$(CORE_BINARY): $(RTL_SOURCES) $(PORTABLE_TB_SOURCE) $(PROGRAM_HEX) | dirs
	@mkdir -p "$(dir $(CORE_BINARY))"
	@iverilog $(IVERILOG_FLAGS) -DRISCV_DEBUG -DPROGRAM_HEX=\"$(PROGRAM_HEX)\" -DPROGRAM_WORDS=$(PROGRAM_WORDS) -s $(PORTABLE_TB_TOP) -o "$@" $(RTL_SOURCES) $(PORTABLE_TB_SOURCE)

test-core: programs-check $(CORE_BINARY) ## Run the self-checking integrated CPU test.
	@set -o pipefail; vvp "$(CORE_BINARY)" +wave="$(CORE_TEST_WAVE)" 2>&1 | tee "$(CORE_LOG)"
	@test -s "$(CORE_TEST_WAVE)"

test: test-unit test-core ## Run all unit and integrated simulations.

test-legacy: dirs ## Compile and run the monolithic and modular legacy RTL.
	@set -euo pipefail; \
	iverilog $(IVERILOG_FLAGS) -s tb_branch_comp -o build/sim/tb_legacy_branch_monolithic.vvp \
		"$(LEGACY_DIR)/hdl.v" "$(LEGACY_DIR)/testbench/tb_branch_comp.v"; \
	vvp build/sim/tb_legacy_branch_monolithic.vvp; \
	iverilog $(IVERILOG_FLAGS) -s tb_branch_comp -o build/sim/tb_legacy_branch_modular.vvp \
		"$(LEGACY_DIR)/rtl/branch_comp.v" "$(LEGACY_DIR)/testbench/tb_branch_comp.v"; \
	vvp build/sim/tb_legacy_branch_modular.vvp; \
	iverilog $(IVERILOG_FLAGS) -s tb_riscv -o build/sim/tb_legacy_monolithic.vvp \
		"$(LEGACY_DIR)/hdl.v" "$(LEGACY_DIR)/testbench/tb_riscv.v"; \
	vvp build/sim/tb_legacy_monolithic.vvp; \
	iverilog $(IVERILOG_FLAGS) -s tb_riscv -o build/sim/tb_legacy_modular.vvp \
		"$(LEGACY_DIR)"/rtl/*.v "$(LEGACY_DIR)/testbench/tb_riscv.v"; \
	vvp build/sim/tb_legacy_modular.vvp; \
	iverilog $(IVERILOG_FLAGS) -s testbench -o build/sim/tb_legacy_wrapper.vvp \
		"$(LEGACY_DIR)/hdl.v" "$(LEGACY_DIR)/testbench/testbench.v"; \
	vvp build/sim/tb_legacy_wrapper.vvp

wave: programs-check $(CORE_BINARY) | dirs ## Run a core test and emit waves/TEST.vcd.
	@set -o pipefail; vvp "$(CORE_BINARY)" +wave="$(WAVE_FILE)" 2>&1 | tee "$(CORE_LOG)"
	@test -s "$(WAVE_FILE)"
	@echo "Waveform: $(WAVE_FILE)"

open-wave: ## Open WAVE (or waves/TEST.vcd) in the Codespaces Surfer editor.
	@bash scripts/open_waveform.sh "$(if $(WAVE),$(WAVE),$(WAVE_FILE))"

synth: dirs ## Synthesize riscv_top and write netlist, JSON, stats, and warnings.
	@python3 scripts/check_sources.py
	@python3 scripts/run_synthesis.py
	@python3 scripts/extract_yosys_warnings.py build/logs/yosys-synth.log reports/synthesis-warnings.txt
	@test -s build/synth/$(TOP_MODULE)_netlist.v
	@test -s build/synth/$(TOP_MODULE).json
	@test -s reports/synthesis-stat.txt
	@echo "Netlist: build/synth/$(TOP_MODULE)_netlist.v"
	@echo "Statistics: reports/synthesis-stat.txt"

schematic: ## Generate build/schematic/MODULE.svg (default MODULE=alu).
	@bash scripts/generate_schematic.sh "$(MODULE)"

chipinventor-portability: ## Generate the static portability report (not a platform validation).
	@python3 scripts/check_chipinventor_portability.py

chipinventor-package: chipinventor-portability ## Generate a deterministic, self-contained package directory.
	@python3 scripts/chipinventor_package.py

chipinventor-check: ## Check and simulate the current package in isolation.
	@python3 scripts/chipinventor_check.py

chipinventor-release: chipinventor-package chipinventor-check ## Archive the checked package without tags or remote releases.
	@python3 scripts/chipinventor_release.py

chipinventor-validation-record: ## Create a blank manual validation record; use DATE=YYYY-MM-DD.
	@python3 scripts/create_chipinventor_validation_record.py "$(DATE)"

chipinventor-status: ## Compare HEAD with the last explicitly approved manual validation.
	@python3 scripts/chipinventor_status.py

openlane-readiness: ## Report missing physical-design parameters without running OpenLane.
	@python3 scripts/openlane_readiness.py

ci: setup-check lint build test synth chipinventor-package chipinventor-check ## Run the GitHub Actions baseline.

clean: ## Remove disposable build, report, and waveform artifacts.
	@rm -rf build waves dist
	@rm -f reports/synthesis-stat.txt reports/synthesis-warnings.txt
