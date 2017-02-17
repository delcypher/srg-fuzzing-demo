#include "interval.h"
#include <unistd.h>
#include <stdio.h>

int main(int argc, char** argv) {
  float input = 0.0f;

  // Get bytes for fuzzing from standard input.
  // `afl-fuzz` places its data there by default.
  unsigned total_read_count = 0;
  while (total_read_count < sizeof(float)) {
    void* buffer_ptr = (((char*) &input) + total_read_count);
    // NOTE: There is a potential hang here if there are no more bytes to read.
    // AFL typically finds this so for the purposes of the demo we'll leave
    // this bug here.
    unsigned read_count = read(/*stdinput*/ 0, buffer_ptr, sizeof(float) - total_read_count);
    total_read_count += read_count;
    printf("Read %u bytes\n", read_count);
  }

  // Fuzz our function
  printf("Got float %f\n", input);
  run_benchmark(input);
  return 0;
}
