# Part of the Crubit project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

# A bindings crate uses types from the bindings crate of its dependency.
cmake_minimum_required(VERSION 3.27)
project(bound_deps LANGUAGES CXX)
include(${CRUBIT_SOURCE_DIR}/cmake/test/fixture_preamble.cmake)

add_library(a INTERFACE)
target_sources(a INTERFACE FILE_SET HEADERS FILES a/a.h)
# `#include "a.h"` resolves only through this non-normalized directory; the
# header must still be attributed to `a`.
target_include_directories(a INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/a/../a)

add_library(b STATIC b.cc)
target_sources(b PUBLIC FILE_SET HEADERS FILES b.h)
# Bindings may be declared before the target's dependencies are.
crubit_rust_bindings(b_rs CC_TARGET b)
target_link_libraries(b PUBLIC a)
crubit_rust_bindings(a_rs CC_TARGET a)

corrosion_import_crate(MANIFEST_PATH rust_test/Cargo.toml)
# Only `b_rs` is listed: its dependency `a_rs` comes along.
crubit_link_rust_bindings(rust_test b_rs)

add_executable(main main.cc)
target_link_libraries(main PRIVATE rust_test)
add_test(NAME main COMMAND main)

# Editing a dependency's header regenerates the dependent's bindings.
add_test(NAME regenerate COMMAND ${CMAKE_COMMAND}
  -DBINARY_DIR=${CMAKE_BINARY_DIR}
  -DHEADER=${CMAKE_CURRENT_SOURCE_DIR}/a/a.h
  -DCRATE=b_rs
  -DGENERATOR=${CMAKE_GENERATOR}
  -P ${CRUBIT_SOURCE_DIR}/cmake/test/check_regenerate.cmake)
