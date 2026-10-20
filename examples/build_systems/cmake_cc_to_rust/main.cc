// Part of the Crubit project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Runs the Rust code, which calls into the C++ greeter library.
extern "C" int run_rust_app();

int main() { return run_rust_app(); }
