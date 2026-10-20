# Part of the Crubit project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

# CMake support for generating Rust bindings for C++ libraries with Crubit
# (`rs_bindings_from_cc`).
#
# Requirements: Clang with libc++, a nightly Rust toolchain (or
# RUSTC_BOOTSTRAP=1, which Crubit sets for the crates it links), and an
# `rs_bindings_from_cc` binary, given by CRUBIT_RS_BINDINGS_FROM_CC.
#
# See docs/overview/build_systems.md.

include_guard(GLOBAL)

include("${CMAKE_CURRENT_LIST_DIR}/internal/CrubitToolchain.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/internal/CrubitClangArgs.cmake")

# Variables set here are visible only in the including directory, so state
# shared with the functions lives in the cache.
get_filename_component(_crubit_source_dir "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
set(CRUBIT_SOURCE_DIR "${_crubit_source_dir}" CACHE INTERNAL "Crubit source directory")
unset(_crubit_source_dir)
