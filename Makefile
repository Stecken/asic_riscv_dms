SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

TOP := riscv_top
TEST ?= core_basic
MODULE ?= alu

RTL_SOURCES := $(shell sed -e '/^[[:space:]]*\#/d' -e '/^[[:space:]]*$$/d' rtl/files.f)
UNIT_TESTS := alu register_file memory immediate_gen control
PROGRAM_HEX := tb/programs/$(TEST).hex
PROGRAM_WORDS := $(shell if test -f "$(PROGRAM_HEX)"; then wc -l < "$(PROGRAM_HEX)"; else echo 0; fi)
CORE_BINARY := build/sim/$(TEST)/tb_core.vvp
CORE_LOG := build/logs/test-core-$(TEST).log
WAVE_FILE := waves/$(TEST).vcd

IVERILOG_FLAGS := -g2012 -Wall -Wimplicit
VERILATOR_FLAGS := --lint-only --top-module $(TOP) -Wall

.PHONY: help setup-check lint build test test-unit test-core wave open-wave \
	programs programs-check synth schematic clean ci dirs

help: ## Show the supported commands.
	@awk 'BEGIN {FS = ":.*## "; print "RISC-V HDL laboratory targets:"} /^[a-zA-Z0-9_-]+:.*## / {printf "  %-18s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

dirs:
	@mkdir -p build/rtl build/sim build/logs build/synth build/schematic reports waves

setup-check: ## Verify tools, versions, and the official source manifest.
	@bash scripts/setup-check.sh

lint: dirs ## Lint every official RTL source with manifest checks, Icarus, and Verilator.
	@python3 scripts/check_sources.py | tee build/logs/source-check.log
	@set -o pipefail; iverilog $(IVERILOG_FLAGS) -s $(TOP) -o build/rtl/$(TOP)-lint.vvp $(RTL_SOURCES) 2>&1 | tee build/logs/iverilog-lint.log
	@set -o pipefail; verilator $(VERILATOR_FLAGS) $(RTL_SOURCES) 2>&1 | tee build/logs/verilator-lint.log

build: dirs ## Compile the official RTL top with Icarus Verilog.
	@set -o pipefail; iverilog $(IVERILOG_FLAGS) -s $(TOP) -o build/rtl/$(TOP).vvp $(RTL_SOURCES) 2>&1 | tee build/logs/build.log
	@echo "Build: build/rtl/$(TOP).vvp"

programs: ## Regenerate checked-in .hex programs with the minimal assembler.
	@for source in tb/programs/*.S; do \
		output="$${source%.S}.hex"; \
		python3 scripts/assemble_test_program.py "$$source" "$$output"; \
		echo "Generated $$output"; \
	done

programs-check: ## Confirm that every checked-in .hex matches its Assembly source.
	@for source in tb/programs/*.S; do \
		output="$${source%.S}.hex"; \
		python3 scripts/assemble_test_program.py --check "$$source" "$$output"; \
	done
	@echo "PASS programs-check"

test-unit: dirs ## Run self-checking ALU, register file, control, memory, and immediate tests.
	@set -euo pipefail; \
	for test_name in $(UNIT_TESTS); do \
		binary="build/sim/tb_$${test_name}.vvp"; \
		log="build/logs/test-unit-$${test_name}.log"; \
		iverilog $(IVERILOG_FLAGS) -DRISCV_DEBUG -s "tb_$${test_name}" -o "$$binary" $(RTL_SOURCES) "tb/unit/tb_$${test_name}.v" 2>&1 | tee "$$log"; \
		vvp "$$binary" 2>&1 | tee -a "$$log"; \
	done

$(CORE_BINARY): $(RTL_SOURCES) tb/core/tb_core.v $(PROGRAM_HEX) | dirs
	@mkdir -p "$(dir $(CORE_BINARY))"
	@iverilog $(IVERILOG_FLAGS) -DRISCV_DEBUG -DPROGRAM_HEX=\"$(PROGRAM_HEX)\" -DPROGRAM_WORDS=$(PROGRAM_WORDS) -s tb_core -o "$@" $(RTL_SOURCES) tb/core/tb_core.v

test-core: programs-check $(CORE_BINARY) ## Run the self-checking integrated CPU test.
	@set -o pipefail; vvp "$(CORE_BINARY)" 2>&1 | tee "$(CORE_LOG)"

test: test-unit test-core ## Run all unit and integrated simulations.

wave: programs-check $(CORE_BINARY) | dirs ## Run a core test and emit waves/TEST.vcd.
	@set -o pipefail; vvp "$(CORE_BINARY)" +wave="$(WAVE_FILE)" 2>&1 | tee "$(CORE_LOG)"
	@test -s "$(WAVE_FILE)"
	@echo "Waveform: $(WAVE_FILE)"

open-wave: ## Open WAVE (or waves/TEST.vcd) in the Codespaces Surfer editor.
	@bash scripts/open_waveform.sh "$(if $(WAVE),$(WAVE),$(WAVE_FILE))"

synth: dirs ## Synthesize riscv_top and write netlist, JSON, stats, and warnings.
	@python3 scripts/check_sources.py
	@yosys -ql build/logs/yosys-synth.log scripts/run_synthesis.ys
	@python3 scripts/extract_yosys_warnings.py build/logs/yosys-synth.log reports/synthesis-warnings.txt
	@test -s build/synth/$(TOP)_netlist.v
	@test -s build/synth/$(TOP).json
	@test -s reports/synthesis-stat.txt
	@echo "Netlist: build/synth/$(TOP)_netlist.v"
	@echo "Statistics: reports/synthesis-stat.txt"

schematic: ## Generate build/schematic/MODULE.svg (default MODULE=alu).
	@bash scripts/generate_schematic.sh "$(MODULE)"

ci: setup-check lint build test synth ## Run the same baseline used by GitHub Actions.

clean: ## Remove disposable build, report, and waveform artifacts.
	@rm -rf build reports waves
