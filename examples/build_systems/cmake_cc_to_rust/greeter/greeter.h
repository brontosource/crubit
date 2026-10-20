// Part of the Crubit project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#ifndef CRUBIT_EXAMPLES_BUILD_SYSTEMS_CMAKE_CC_TO_RUST_GREETER_GREETER_H_
#define CRUBIT_EXAMPLES_BUILD_SYSTEMS_CMAKE_CC_TO_RUST_GREETER_GREETER_H_

#include <string>
#include <vector>

#include "absl/time/time.h"

// Returns "Hello, <name>!".
std::string Greet(const std::string& name);

// Returns {0, 1, ..., n - 1}.
std::vector<int> Range(int n);

// Abseil has no Rust bindings in this project, so Crubit skips this function.
absl::Duration Timeout();

#endif  // CRUBIT_EXAMPLES_BUILD_SYSTEMS_CMAKE_CC_TO_RUST_GREETER_GREETER_H_
