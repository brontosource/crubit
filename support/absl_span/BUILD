# Part of the Crubit project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

load(
    "//rs_bindings_from_cc/bazel_support:additional_rust_srcs_for_crubit_bindings_aspect_hint.bzl",
    "additional_rust_srcs_for_crubit_bindings",
)

package(default_applicable_licenses = ["//:license"])

# The Rust types that Crubit maps `absl::Span<T>` to. This is an aspect hint for
# `@abseil-cpp//absl/types:span` (see //patches:abseil_crubit_aspect_hints.patch).
additional_rust_srcs_for_crubit_bindings(
    name = "span",
    srcs = ["span.rs"],
    namespace_path = "absl",
    visibility = ["//visibility:public"],
)
