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
include("${CMAKE_CURRENT_LIST_DIR}/internal/CrubitGenerate.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/internal/CrubitStd.cmake")

# Variables set here are visible only in the including directory, so state
# shared with the functions lives in the cache.
get_filename_component(_crubit_source_dir "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
set(CRUBIT_SOURCE_DIR "${_crubit_source_dir}" CACHE INTERNAL "Crubit source directory")
unset(_crubit_source_dir)

# crubit_link_rust_bindings(<rust_target> [<crate>...])
#
# Makes the bindings crates `<crate>...` (created by crubit_rust_bindings), and
# the C++ standard library bindings crate `cc_std`, available to the Rust
# target `<rust_target>` imported with `corrosion_import_crate`. The crate's
# Cargo.toml depends on them as `<crate> = "0.0.0"`.
function(crubit_link_rust_bindings rust_target)
  _crubit_init_toolchain()
  _crubit_ensure_std()
  if(NOT TARGET _cargo-build_${rust_target})
    message(FATAL_ERROR
      "crubit_link_rust_bindings: ${rust_target} is not a Rust target imported "
      "with corrosion_import_crate")
  endif()
  foreach(crate IN ITEMS cc_std ${ARGN})
    add_dependencies(_cargo-build_${rust_target} crubit_generate_${crate})
    target_link_libraries(${rust_target} INTERFACE crubit::${crate})
  endforeach()
  get_target_property(flags ${rust_target} INTERFACE_CORROSION_CARGO_FLAGS)
  if(NOT "${CRUBIT_CARGO_CONFIG}" IN_LIST flags)
    corrosion_set_cargo_flags(${rust_target} --config "${CRUBIT_CARGO_CONFIG}")
    # Generated bindings use unstable Rust features.
    corrosion_set_env_vars(${rust_target} RUSTC_BOOTSTRAP=1)
  endif()
endfunction()
