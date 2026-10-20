# Part of the Crubit project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

# Copies the rs_bindings_from_cc param file IN to OUT, normalizing the
# directory of each `-I<dir>` line (so `inc/../inc` becomes `inc`).
#
#   cmake -DIN=<file> -DOUT=<file> -P CrubitNormalizeIncludes.cmake
#
# The file is processed a line at a time without CMake lists, which would
# split lines at `;` and treat `[` and `]` specially.

cmake_minimum_required(VERSION 3.22)

file(READ "${IN}" rest)
set(out "")
while(NOT rest STREQUAL "")
  string(FIND "${rest}" "\n" eol)
  if(eol EQUAL -1)
    set(line "${rest}")
    set(rest "")
    set(newline "")
  else()
    string(SUBSTRING "${rest}" 0 ${eol} line)
    math(EXPR eol "${eol} + 1")
    string(SUBSTRING "${rest}" ${eol} -1 rest)
    set(newline "\n")
  endif()
  if(line MATCHES "^-I(.+)$")
    set(dir "${CMAKE_MATCH_1}")
    cmake_path(NORMAL_PATH dir)
    set(line "-I${dir}")
  endif()
  string(APPEND out "${line}${newline}")
endwhile()
file(WRITE "${OUT}" "${out}")
