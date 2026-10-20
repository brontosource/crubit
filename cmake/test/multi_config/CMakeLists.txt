# Part of the Crubit project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

# Multi-config generators are rejected with a clear message.
cmake_minimum_required(VERSION 3.22)
project(multi_config LANGUAGES CXX)
include(${CRUBIT_SOURCE_DIR}/cmake/test/fixture_preamble.cmake)

add_library(lib INTERFACE)
crubit_rust_bindings(lib_rs CC_TARGET lib HEADERS lib.h)
