#include "interval.h"
#include <stdint.h>
#include <string.h> // For memcpy()

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  if (size < sizeof(float))
    return 0;

  // Make fuzzed float
  float input = 0.0f;
  memcpy(&input, data, sizeof(float));

  // Run the benchmark with the fuzzed value
  run_benchmark(input);
  return 0;
}
