# Part of the Crubit project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

# OSS stand-in for Google's internal //third_party/stl. In OSS builds the C++
# standard library is supplied implicitly by the C++ toolchain, so these targets
# carry no headers of their own.

load("@rules_cc//cc:cc_library.bzl", "cc_library")

package(default_visibility = ["//visibility:public"])

cc_library(name = "stl")

filegroup(
    name = "stl_headers",
    srcs = [],
)
