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

# crubit_rust_bindings(<crate> CC_TARGET <target>
#                      [HEADERS <header>...]
#                      [FEATURES <feature>...])
#
# Generates Rust bindings for the C++ library `<target>` as the Rust crate
# `<crate>`, and the C++ library `crubit::<crate>` holding the C++ side of the
# bindings. Use crubit_link_rust_bindings to use the crate from Rust.
#
# HEADERS are the public headers to generate bindings for (relative to the
# current source directory); by default, the target's `HEADERS` file set.
# FEATURES are the Crubit features enabled for the target (default:
# `supported`); see docs/overview/status.md.
function(crubit_rust_bindings crate)
  cmake_parse_arguments(PARSE_ARGV 1 ARG "" "CC_TARGET" "HEADERS;FEATURES")
  if(NOT ARG_CC_TARGET OR NOT TARGET "${ARG_CC_TARGET}")
    message(FATAL_ERROR
      "crubit_rust_bindings(${crate}): CC_TARGET must name a C++ library target")
  endif()
  _crubit_init_toolchain()
  set(tgt "${ARG_CC_TARGET}")
  get_target_property(aliased ${tgt} ALIASED_TARGET)
  if(aliased)
    set(tgt "${aliased}")
  endif()

  set(headers "")
  foreach(header IN LISTS ARG_HEADERS)
    cmake_path(ABSOLUTE_PATH header NORMALIZE)
    list(APPEND headers "${header}")
  endforeach()
  if(NOT ARG_FEATURES)
    set(ARG_FEATURES supported)
  endif()
  # Crubit's `cxx` crate interop is not supported with CMake.
  list(APPEND ARG_FEATURES no_impl_cxx_extern_type)

  set_target_properties(${tgt} PROPERTIES
    CRUBIT_CRATE_NAME "${crate}"
    CRUBIT_HEADERS "${headers}"
    CRUBIT_FEATURES "${ARG_FEATURES}")
  # Generate once all targets and their dependencies are known. (Arguments of
  # deferred calls are evaluated late, so bind `tgt` now.)
  cmake_language(EVAL CODE
    "cmake_language(DEFER DIRECTORY [[${CMAKE_SOURCE_DIR}]] CALL _crubit_finalize [[${tgt}]])")
endfunction()

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
