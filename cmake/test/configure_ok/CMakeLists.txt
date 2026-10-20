# Part of the Crubit project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

# The Crubit module configures and accepts a valid toolchain.
cmake_minimum_required(VERSION 3.23)
project(configure_ok LANGUAGES CXX)
include(${CRUBIT_SOURCE_DIR}/cmake/test/fixture_preamble.cmake)

_crubit_init_toolchain()
if(NOT EXISTS "${CRUBIT_CARGO_CONFIG}")
  message(FATAL_ERROR "Crubit did not write its cargo config")
endif()

add_executable(main main.cc)
add_test(NAME main COMMAND main)
