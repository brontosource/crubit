"""Consume some simple types and functions from //third_party/absl."""

load("//common:crubit_wrapper_macros_oss.bzl", "crubit_rust_test")
# Only used by targets disabled in OSS (see below).
# load("//rs_bindings_from_cc/test:test_bindings.bzl", "crubit_test_cc_library")
# load(
#     "//rs_bindings_from_cc/test/golden:golden_test.bzl",
#     "golden_test",
# )

package(default_applicable_licenses = ["//:license"])

crubit_rust_test(
    name = "main",
    srcs = ["test.rs"],
    cc_deps = ["@abseil-cpp//absl/time"],
)

# Disabled in OSS: needs the Google-internal Crubit ABI for absl::AnyInvocable
# (absl/functional/any_invocable_crubit_abi.h, and the Rust AnyInvocableAbi and
# RawAnyInvocable types).
# crubit_test_cc_library(
#     name = "absl_functional",
#     hdrs = ["absl_functional.h"],
#     aspect_hints = ["//features:supported"],
#     deps = [
#         "@abseil-cpp//absl/functional:any_invocable",
#     ],
# )

# Disabled in OSS: needs the Google-internal Crubit ABI for absl::AnyInvocable
# (absl/functional/any_invocable_crubit_abi.h, and the Rust AnyInvocableAbi and
# RawAnyInvocable types).
# golden_test(
#     name = "absl_functional_golden_test",
#     cc_library = "absl_functional",
#     golden_cc = "absl_functional.golden.cc",
#     golden_rs = "absl_functional.golden.rs",
# )

# Disabled in OSS: needs the Google-internal Crubit ABI for absl::AnyInvocable
# (absl/functional/any_invocable_crubit_abi.h, and the Rust AnyInvocableAbi and
# RawAnyInvocable types).
# crubit_test_cc_library(
#     name = "uses_anyinvocable",
#     srcs = ["uses_anyinvocable.cc"],
#     hdrs = ["uses_anyinvocable.h"],
#     aspect_hints = [
#         "//features:layout_compat_optional",
#         # Required to support incomplete types.
#         "//features:forward_declare",
#     ],
#     deps = [
#         "@abseil-cpp//absl/functional:any_invocable",
#     ],
# )

# Disabled in OSS: needs the Google-internal Crubit ABI for absl::AnyInvocable
# (absl/functional/any_invocable_crubit_abi.h, and the Rust AnyInvocableAbi and
# RawAnyInvocable types).
# crubit_rust_test(
#     name = "uses_anyinvocable_test",
#     srcs = ["uses_anyinvocable_test.rs"],
#     cc_deps = [
#         ":uses_anyinvocable",
#         "@abseil-cpp//absl/functional:any_invocable",
#     ],
#     deps = [
#         "@crate_index//:googletest",
#     ],
# )

# crubit_test_cc_library(
#     name = "any_invocable_alias",
#     hdrs = ["any_invocable_alias.h"],
#     aspect_hints = ["//features:supported"],
#     deps = [
#         "@abseil-cpp//absl/functional:any_invocable",
#     ],
# )

# Depends on the AnyInvocable bridge only through `:any_invocable_alias`. Checks
# that the generated bindings can include the bridge's support header.
# crubit_test_cc_library(
#     name = "uses_any_invocable_alias",
#     hdrs = ["uses_any_invocable_alias.h"],
#     aspect_hints = ["//features:supported"],
#     deps = [
#         ":any_invocable_alias",
#     ],
# )

# crubit_rust_test(
#     name = "uses_any_invocable_alias_test",
#     srcs = ["uses_any_invocable_alias_test.rs"],
#     cc_deps = [
#         ":uses_any_invocable_alias",
#     ],
#     deps = [
#         "@crate_index//:googletest",
#     ],
# )

crubit_rust_test(
    name = "int128_test",
    srcs = ["int128_test.rs"],
    cc_deps = [
        "@abseil-cpp//absl/numeric:int128",
    ],
    deps = [
        "@crate_index//:googletest",
    ],
)
