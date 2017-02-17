# Fuzzing demo

## Building the fuzzers

# AFL

```
make afl
```

# LibFuzzer

Note the copy of LibFuzzer here is from LLVM 3.9.
LibFuzzer is very tightly coupled with Clang and Compiler-rt
so you need to use Clang 3.9 built with the corresponding compiler-rt.

```
make libfuzzer
```

## Running the `interval` demo

To fuzz using libfuzzer:

```
make fuzz_interval_libfuzzer
```

To fuzz using AFL:

```
make fuzz_interval_afl
```
