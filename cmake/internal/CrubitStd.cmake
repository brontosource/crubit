# Part of the Crubit project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

include_guard(GLOBAL)

# Sets `out_var` to the entries of list `list_name` in
# support/cc_std_impl/headers.bzl, skipping commented-out entries.
function(_crubit_read_std_header_list out_var list_name)
  file(READ "${CRUBIT_SOURCE_DIR}/support/cc_std_impl/headers.bzl" bzl)
  if(NOT bzl MATCHES "${list_name} = \\[([^]]*)\\]")
    message(FATAL_ERROR "Crubit: ${list_name} not found in headers.bzl")
  endif()
  string(REPLACE "\n" ";" lines "${CMAKE_MATCH_1}")
  set(headers "")
  foreach(line IN LISTS lines)
    if(line MATCHES "^ *\"([^\"]+)\"")
      list(APPEND headers "${CMAKE_MATCH_1}")
    endif()
  endforeach()
  set(${out_var} "${headers}" PARENT_SCOPE)
endfunction()

# Creates the `cc_std` bindings crate (Rust bindings for the C++ standard
# library) and `crubit::cc_std`, once per build.
function(_crubit_ensure_std)
  if(TARGET crubit_impl_cc_std)
    return()
  endif()
  _crubit_read_std_header_list(libcxx_headers LIBCXX_HEADERS)
  _crubit_read_std_header_list(libc_headers LIBC_HEADERS)
  _crubit_system_include_args(system_args)

  # Find the standard library headers exactly as Clang spells them, by
  # preprocessing a file that includes all of them.
  set(dir "${CRUBIT_CRATES_DIR}/cc_std")
  set(tu "${dir}/all_std_headers.cc")
  set(tu_content "")
  foreach(header IN LISTS libcxx_headers libc_headers)
    string(APPEND tu_content "#include <${header}>\n")
  endforeach()
  file(WRITE "${tu}" "${tu_content}")
  separate_arguments(cxx_flags UNIX_COMMAND "${CMAKE_CXX_FLAGS}")
  execute_process(
    COMMAND "${CMAKE_CXX_COMPILER}" -x c++ -std=c++20 ${cxx_flags} ${system_args}
            -E -M -MF "${dir}/all_std_headers.d" "${tu}"
    OUTPUT_QUIET
    ERROR_VARIABLE error
    RESULT_VARIABLE result)
  if(NOT result EQUAL 0)
    message(FATAL_ERROR "Crubit: failed to locate C++ standard library headers:\n${error}")
  endif()
  file(READ "${dir}/all_std_headers.d" depfile)
  string(REGEX REPLACE "^[^:]*:" "" depfile "${depfile}")
  string(REGEX REPLACE "\\\\\n" " " depfile "${depfile}")
  separate_arguments(deps UNIX_COMMAND "${depfile}")
  list(REMOVE_ITEM deps "${tu}")

  set(all_headers "")
  foreach(dep IN LISTS deps)
    cmake_path(NORMAL_PATH dep)
    list(APPEND all_headers "${dep}")
  endforeach()

  set(public_headers "")
  foreach(header IN LISTS libcxx_headers libc_headers)
    set(found "")
    foreach(dep IN LISTS all_headers)
      if(header IN_LIST libcxx_headers AND dep MATCHES "/c\\+\\+/v1/${header}$")
        set(found "${dep}")
      elseif(header IN_LIST libc_headers AND dep MATCHES "/${header}$"
             AND NOT dep MATCHES "/c\\+\\+/v1/")
        set(found "${dep}")
      endif()
      if(found)
        break()
      endif()
    endforeach()
    if(NOT found)
      message(FATAL_ERROR "Crubit: standard library header <${header}> not found")
    endif()
    list(APPEND public_headers "${found}")
  endforeach()

  set(impl "${CRUBIT_SOURCE_DIR}/support/cc_std_impl")
  foreach(helper IN ITEMS allocator.h conversion_function_helpers.h macos_sdk_workarounds.h)
    list(APPEND public_headers "${impl}/${helper}")
    list(APPEND all_headers "${impl}/${helper}")
  endforeach()

  list(JOIN all_headers "\",\"" json_headers)
  set(label "//support/cc_std:cc_std")
  set(target_args
    "{\"t\":\"${label}\",\"h\":[\"${json_headers}\"],\"f\":[\"all\",\"no_impl_cxx_extern_type\"],\"c\":\"cc_std\"}")
  # Every other bindings crate needs this entry too.
  set_property(GLOBAL PROPERTY _CRUBIT_STD_TARGET_ARGS "${target_args}")
  _crubit_generate(
    CRATE cc_std
    LABEL "${label}"
    CLANG_ARGS -x c++ -std=c++20 ${cxx_flags} ${system_args}
    PUBLIC_HEADERS ${public_headers}
    TARGET_ARGS_JSON "${target_args}"
    EXTRA_RS_SRCS
      "${impl}/lossy_utf8.rs"
      "${impl}/slice_ptr.rs"
      "${impl}/allocator.rs=std"
      "${impl}/non_null.rs=std"
      "${impl}/nullable.rs=std"
      "${impl}/optional.rs=std"
      "${impl}/shared_ptr.rs=std"
      "${impl}/string.rs=std"
      "${impl}/string_view.rs=std"
      "${impl}/unique_ptr.rs=std"
      "${impl}/vector.rs=std"
      "${impl}/vector_partial_eq.rs=std")
endfunction()
