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

clean::
	cd $(AFL_DIR) && make clean
	cd $(AFL_DIR)/llvm_mode && make clean

# FIXME: This is lame. We should only rebuild when necessary
libfuzzer: $(LIBFUZZER_DIR)/libFuzzer.a

$(LIBFUZZER_DIR)/libFuzzer.a:
	cd $(LIBFUZZER_DIR) && ./build.sh

clean::
	cd $(LIBFUZZER_DIR) && rm -f libFuzzer.a

###############################################################################
# Common build flags
###############################################################################

# Note current LibFuzzer docs says to use `-fsanitizer-coverage=trace-pc-guard`
# but Clang 3.9 doesn't support that and Clang 4.0 hasn't been released yet so
# just use `-fsanitize-coverage=edge` for now.
LIBFUZZER_BUILD_FLAGS := -fsanitize-coverage=edge \
  -fno-omit-frame-pointer \
  -fsanitize=address \
  -L $(LIBFUZZER_DIR)/ \
  -lFuzzer

AFLFUZZ_ENV:= \
	AFL_SKIP_CPUFREQ=1

###############################################################################
# Simple benchmark
###############################################################################
simple_libfuzzer: demos/simple/foo.cc demos/simple/foo.h demos/simple/libfuzzer_driver.cc libfuzzer
	clang++ \
		$(CFLAGS) \
		$(LIBFUZZER_BUILD_FLAGS) \
		$(interval_benchmark_flags) \
		$(filter %.cc, $^) \
		-o $@

fuzz_simple_libfuzzer: simple_libfuzzer
	./$<

simple_afl: demos/simple/foo.cc demos/simple/foo.h demos/simple/afl_driver.cc afl
	$(AFLCXX) \
		$(CFLAGS) \
		$(interval_benchmark_flags) \
		$(filter %.cc, $^) \
		-o $@

clean::
	rm -f simple_afl simple_libfuzzer

# Fuzz using AFL. We seed with an input
# that we know doesn't cause a crash.
fuzz_simple_afl: simple_afl
	mkdir -p simple_afl_inputs
	@echo "Creating dummy input"
	echo "hello" > simple_afl_inputs/0
	mkdir -p simple_afl_outputs
	$(AFLFUZZ_ENV) $(AFLFUZZ) \
		-i ./simple_afl_inputs \
		-o ./simple_afl_outputs \
		./$<

# FIXME: Do this properly
clean::
	rm -rf simple_afl_inputs simple_afl_outputs

###############################################################################
# Interval benchmark
###############################################################################
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

clean::
	rm -f interval_afl interval_libfuzzer

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

.PHONY: all afl libfuzzer help fuzz_interval_afl clean fuzz_simple_libfuzzer fuzz_simple_afl
