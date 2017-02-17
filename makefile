NPROC=$(shell nproc)

AFL_DIR := afl/afl-2.39b
LIBFUZZER_DIR := LibFuzzer

AFLCXX := $(AFL_DIR)/afl-g++
AFLFUZZ := $(AFL_DIR)/afl-fuzz
CFLAGS := -Wall -g

all:: help

help:
	@echo "Run"
	@echo ""
	@echo "Targets:"
	@echo ""
	@echo "afl"
	@echo "clean"
	@echo "fuzz_interval_libfuzzer"
	@echo "fuzz_interval_afl"
	@echo "help"
	@echo "interval_afl"
	@echo "interval_libfuzzer"
	@echo "libfuzzer"
	@echo ""

afl:
	cd $(AFL_DIR) && env MAKEFLAGS="" make -j$(NPROC)
	cd $(AFL_DIR)/llvm_mode && env MAKEFLAGS="" make -j$(NPROC)

# FIXME: This is lame. We should only rebuild when necessary
libfuzzer: $(LIBFUZZER_DIR)/libFuzzer.a

$(LIBFUZZER_DIR)/libFuzzer.a:
	cd LibFuzzer && ./build.sh

  #-fsanitizer-coverage=trace-pc-guard
LIBFUZZER_BUILD_FLAGS := -fsanitize-coverage=edge \
  -fno-omit-frame-pointer \
  -fsanitize=address \
  -L $(LIBFUZZER_DIR)/ \
  -lFuzzer

interval_benchmark_flags := -DBUG=0 -DN=7

# FIXME: Clang 3.9 miscompiles at -O2
interval_libfuzzer: demos/interval/interval.cc demos/interval/interval.h demos/interval/libfuzzer_driver.cc libfuzzer
	clang++ \
		$(CFLAGS) \
		$(LIBFUZZER_BUILD_FLAGS) \
		$(interval_benchmark_flags) \
		$(filter %.cc, $^) \
		-o $@

fuzz_interval_libfuzzer: interval_libfuzzer
	./$<

interval_afl: demos/interval/interval.cc demos/interval/interval.h demos/interval/afl_driver.cc afl
	$(AFLCXX) \
		$(CFLAGS) \
		$(interval_benchmark_flags) \
		$(filter %.cc, $^) \
		-o $@

AFLFUZZ_ENV:= \
	AFL_SKIP_CPUFREQ=1

# Fuzz using AFL. We seed with an input
# that we know doesn't cause a crash.
fuzz_interval_afl: interval_afl
	mkdir -p interval_afl_inputs
	@echo "Creating dummy input"
	echo -e "\x00\x00\x00\x00" > interval_afl_inputs/0
	mkdir -p interval_afl_outputs
	$(AFLFUZZ_ENV) $(AFLFUZZ) \
		-i ./interval_afl_inputs \
		-o ./interval_afl_outputs \
		./$<

# FIXME: Do this properly
clean::
	rm -rf interval_afl_inputs interval_afl_outputs

.PHONY: all afl libfuzzer help fuzz_interval_afl clean
