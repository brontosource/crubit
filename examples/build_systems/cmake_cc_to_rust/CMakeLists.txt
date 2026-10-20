# Part of the Crubit project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

# Calling an existing C++ library (which uses the C++ standard library and
# Abseil) from Rust, with Crubit and CMake. See README.md.
cmake_minimum_required(VERSION 3.22)
project(cmake_cc_to_rust LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(FetchContent)
# Use an installed Abseil if there is one.
find_package(absl QUIET)
if(NOT absl_FOUND)
  FetchContent_Declare(
    absl
    GIT_REPOSITORY https://github.com/abseil/abseil-cpp.git
    GIT_TAG 20260526.0
    GIT_SHALLOW TRUE
  )
  FetchContent_MakeAvailable(absl)
endif()
FetchContent_Declare(crubit SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../..")
FetchContent_Declare(
  Corrosion
  GIT_REPOSITORY https://github.com/corrosion-rs/corrosion
  GIT_TAG v0.6.1
  GIT_SHALLOW TRUE
)
FetchContent_MakeAvailable(crubit Corrosion)

# The existing C++ library.
add_library(greeter STATIC greeter/greeter.cc)
target_include_directories(greeter PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/greeter>)
target_link_libraries(greeter PUBLIC absl::strings absl::time)

# Rust bindings for it, as the crate `greeter_rs`.
crubit_rust_bindings(greeter_rs CC_TARGET greeter HEADERS greeter/greeter.h)

# A Rust crate that uses them.
corrosion_import_crate(MANIFEST_PATH rust_app/Cargo.toml)
crubit_link_rust_bindings(rust_app greeter_rs)

add_executable(main main.cc)
target_link_libraries(main PRIVATE rust_app)

enable_testing()
add_test(NAME main COMMAND main)
