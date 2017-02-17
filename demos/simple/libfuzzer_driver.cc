#include "foo.h"
#include <stdint.h>
#include <string.h> // For memcpy()

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  // Run the benchmark with the fuzzed value
  run_benchmark((char*) data, size);
  return 0;
}
