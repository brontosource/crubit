# Part of the Crubit project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

include_guard(GLOBAL)

set(CRUBIT_RS_BINDINGS_FROM_CC "" CACHE FILEPATH
  "Path to the rs_bindings_from_cc binary used to generate Rust bindings")

# Validates the toolchain and initializes Crubit's global state. Runs once per
# configure; called by every public Crubit function, so that projects which
# include Crubit only for its C++ support libraries are not affected.
#
# Sets (as INTERNAL cache entries):
#   CRUBIT_CRATES_DIR:   directory holding generated bindings crates.
#   CRUBIT_CARGO_CONFIG: cargo config file that patches those crates in.
function(_crubit_init_toolchain)
  get_property(initialized GLOBAL PROPERTY _CRUBIT_TOOLCHAIN_INITIALIZED)
  if(initialized)
    return()
  endif()
  set_property(GLOBAL PROPERTY _CRUBIT_TOOLCHAIN_INITIALIZED TRUE)

  if(NOT CRUBIT_RS_BINDINGS_FROM_CC)
    find_program(_crubit_tool NAMES rs_bindings_from_cc)
    if(_crubit_tool)
      set_property(CACHE CRUBIT_RS_BINDINGS_FROM_CC PROPERTY VALUE "${_crubit_tool}")
    endif()
    unset(_crubit_tool CACHE)
  endif()
  if(NOT EXISTS "${CRUBIT_RS_BINDINGS_FROM_CC}")
    message(FATAL_ERROR
      "Crubit: rs_bindings_from_cc not found. Set CRUBIT_RS_BINDINGS_FROM_CC to "
      "the path of an rs_bindings_from_cc binary (see docs/cpp/building.md).")
  endif()

  include(CheckCXXSourceCompiles)
  check_cxx_source_compiles([[
    #include <version>
    #ifndef _LIBCPP_VERSION
    #error not libc++
    #endif
    int main() {}
  ]] CRUBIT_HAS_LIBCXX)
  if(NOT CRUBIT_HAS_LIBCXX)
    message(FATAL_ERROR
      "Crubit requires libc++ (set -stdlib=libc++ in CMAKE_CXX_FLAGS and build "
      "all C++ code, including dependencies, against it).")
  endif()

  set(crates_dir "${CMAKE_BINARY_DIR}/crubit_crates")
  set(CRUBIT_CRATES_DIR "${crates_dir}" CACHE INTERNAL "")
  set(CRUBIT_CARGO_CONFIG "${crates_dir}/cargo-config.toml" CACHE INTERNAL "")
  file(WRITE "${CRUBIT_CARGO_CONFIG}" "[patch.crates-io]\n")
endfunction()
