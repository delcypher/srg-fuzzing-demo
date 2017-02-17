#include "foo.h"
#include <stdio.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char** argv) {
  char inputBuffer[100];
  
  // Make sure the whole buffer is zero initialized
  // so that we get deterministic behaviour.
  memset(inputBuffer, /*c=*/0, sizeof(inputBuffer));

  // Get bytes for fuzzing from standard input.
  // `afl-fuzz` places its data there by default.
  unsigned read_count = read(
    /*stdinput*/ 0,
    &inputBuffer,
    sizeof(inputBuffer));

  // Fuzz our function
  run_benchmark(inputBuffer, read_count);
  return 0;
}
