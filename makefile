NPROC=$(shell nproc)

AFL_DIR := afl/afl-2.39b
LIBFUZZER_DIR := LibFuzzer

AFLCC := $(AFL_DIR)/afl-gcc

all:: help

help:
	@echo "Run"
	@echo ""
	@echo "Targets:"
	@echo ""
	@echo "afl"
	@echo "help"
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

# FIXME: Clang 3.9 miscompiles at -O2
interval_libfuzzer: demos/interval/interval.cc demos/interval/interval.h demos/interval/libfuzzer_driver.cc libfuzzer
	clang++ \
		-Wall \
		-O0 \
		-g \
		$(LIBFUZZER_BUILD_FLAGS) \
		-DBUG=0 \
		-DN=7 \
		$(filter %.cc, $?) \
		-o $@

.PHONY: all afl libfuzzer help interval_libfuzzer
