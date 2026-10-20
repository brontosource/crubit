# Calling C++ from Rust with CMake

A CMake project whose C++ library, `greeter`, uses the C++ standard library and
Abseil. Rust code in `rust_app` calls it through Crubit-generated bindings.

```sh
cmake -S . -B build \
  -DCRUBIT_RS_BINDINGS_FROM_CC=/path/to/rs_bindings_from_cc
cmake --build build
ctest --test-dir build
```

On Linux, also pass `-DCMAKE_CXX_COMPILER=clang++ -DCMAKE_CXX_FLAGS=-stdlib=libc++`.

See [Build System Integrations](../../../docs/overview/build_systems.md) for
details.
