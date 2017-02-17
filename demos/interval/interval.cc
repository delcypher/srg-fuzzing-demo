// Performs an additive computation using double-precision arithmetic
// and single-precision interval arithmetic, and asserts that the
// double-precision result is contained in the single-precision
// interval.
//
// Defines:
// BUG - if 0 then there is no bug and the program should be deemed correct
//     - if 1 then there is a bug (the rounding during interval
//       addition is wrong) and the program should be deemed incorrect
// N   - Specifies the number of additions to be performed.

#include <assert.h>
#include <fenv.h>
#include <math.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#ifndef N
#error "Define N, the number of additions to be performed."
#endif

#ifndef BUG
#error "Define BUG to be 0 or 1"
#endif

// A single-precision interval
typedef struct interval_s {
  float lower;
  float upper;
} interval_t;

// Neither component of an interval should be NaN, and lower and upper should be ordered.
bool well_formed_interval(interval_t a) {
  return !isnan(a.lower) && !isnan(a.upper) && a.lower <= a.upper;
}

interval_t add_intervals(interval_t a, interval_t b) {
  assert(well_formed_interval(a));
  assert(well_formed_interval(b));
  int old_mode = fegetround(); // Save the rounding mode
  fesetround(FE_DOWNWARD); // Set to round down, to compute lower bound for interval
  float lower = a.lower + b.lower;
#if !BUG
  fesetround(FE_UPWARD); // Set to round up, to record upper bound for interval
#endif
  float upper = a.upper + b.upper;
  fesetround(old_mode); // Restore the original rounding mode
  interval_t result = { lower, upper }; // The result is the interval comprised of the computed lower bound and the computed upper bound
  return result;
}

// Determines whether the given double-precision number is inside the single-precision interval.
bool in_interval(double x, interval_t a) {
  assert(!isnan(x));
  assert(well_formed_interval(a));
  return x >= (double)a.lower && x <= (double)a.upper;
}

#define soft_assert(X) do { if (!(X)) { printf("soft assert fail: %s\n", #X); return 0;}} while(0)

#define dumping_assert(X) do { if (!(X)) { dump_float("initial", initial); assert(X);}} while(0)

void dump_float(const char* name, float f) {
  uint32_t bits = 0;
  memcpy(&bits, &f, sizeof(float));
  fprintf(stderr, "%s: %f (%a) (0x%08x)\n", name, f, f, bits);
}


extern "C" int run_benchmark(float initial) {
  dump_float("initial", initial);
  // The program adds 'increment' to 'initial' N times.
  // With e.g. N=7 and BUG=1, these values cause failure
  float increment = 5000000.0f;

  // The addition is performed relatively precisely, using a double,
  // as well as imprecisely, using a single-precision interval
  double precise;
  interval_t imprecise;
  
  // We are not interested in NaNs for this benchmark
  if(isnan(initial) || isnan(increment)) {
    return 0;
  }

  // Avoid infinities otherwise we'll eventually we
  // might do  "inf + inf" which will give NaN.
  if (isinf(initial) || isinf(increment)) {
    return 0;
  }

  // Initialise the double and the interval
  precise = (double)initial;
  imprecise.lower = initial;
  imprecise.upper = initial;
  // soft_assert(well_formed_interval(imprecise));
  assert(well_formed_interval(imprecise));

  // Do the arithmetic and tests
  for(int i = 0; i < N; i++) {
    // soft_assert(in_interval(precise, imprecise));
    //dumping_assert(in_interval(precise, imprecise));
    assert(in_interval(precise, imprecise));
    precise += (double)increment;
    interval_t increment_interval = { increment, increment };
    imprecise = add_intervals(imprecise, increment_interval);
  }
  // Can this assert fail?
  assert(in_interval(precise, imprecise));
  //dumping_assert(in_interval(precise, imprecise));
  return 0;
}
