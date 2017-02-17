#include "foo.h"
#include <stdlib.h>

extern "C" int run_benchmark(char* value, size_t len) {
  if (len < 4) return 0;

  if (value[0] == 'f') {
    if (value[1] == 'o') {
      if (value[2] == 'o') {
        if (value[3] == '!') {
          // Can the fuzzer find this?
          abort();
        }
      }
    }
  }
  return 0;
}
