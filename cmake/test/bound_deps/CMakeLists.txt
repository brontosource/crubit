# Part of the Crubit project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

# A bindings crate uses types from the bindings crate of its dependency.
cmake_minimum_required(VERSION 3.23)
project(bound_deps LANGUAGES CXX)
include(${CRUBIT_SOURCE_DIR}/cmake/test/fixture_preamble.cmake)

add_library(a INTERFACE)
target_sources(a PUBLIC FILE_SET HEADERS BASE_DIRS a FILES a/a.h)
# A non-normalized include directory: headers must still be attributed to `a`.
target_include_directories(a INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/a/../a)

add_library(b STATIC b.cc)
target_sources(b PUBLIC FILE_SET HEADERS FILES b.h)
# Bindings may be declared before the target's dependencies are.
crubit_rust_bindings(b_rs CC_TARGET b)
target_link_libraries(b PUBLIC a)
crubit_rust_bindings(a_rs CC_TARGET a)

corrosion_import_crate(MANIFEST_PATH rust_test/Cargo.toml)
crubit_link_rust_bindings(rust_test a_rs b_rs)

add_executable(main main.cc)
target_link_libraries(main PRIVATE rust_test)
add_test(NAME main COMMAND main)
