# load("@rules_cc//cc:cc_library.bzl", "cc_library")  # Only used by targets disabled in OSS.
load("@rules_cc//cc:cc_test.bzl", "cc_test")
load("@rules_rust//rust:defs.bzl", "rust_library")
load(
    "//bazel:cpp_api_from_rust.bzl",
    "cpp_api_from_rust",
)
# Only used by targets disabled in OSS.
# load(
#     "//bazel:rust_api_from_cpp.bzl",
#     "rust_api_from_cpp",
# )

licenses(["notice"])

# Disabled in OSS: needs the Google-internal Crubit ABI for absl::AnyInvocable
# (absl/functional/any_invocable_crubit_abi.h, and the Rust AnyInvocableAbi and
# RawAnyInvocable types).
# cc_library(
#     name = "cpp_api",
#     srcs = ["cpp_api.cc"],
#     hdrs = ["cpp_api.h"],
#     aspect_hints = [":cpp_api_rust.hint"],
#     deps = [
#         "@abseil-cpp//absl/functional:any_invocable",
#     ],
# )

# Disabled in OSS: needs the Google-internal Crubit ABI for absl::AnyInvocable
# (absl/functional/any_invocable_crubit_abi.h, and the Rust AnyInvocableAbi and
# RawAnyInvocable types).
# rust_api_from_cpp(
#     name = "cpp_api_rust",
#     cpp_target = ":cpp_api",
# )

# Disabled in OSS: needs the Google-internal Crubit ABI for absl::AnyInvocable
# (absl/functional/any_invocable_crubit_abi.h, and the Rust AnyInvocableAbi and
# RawAnyInvocable types).
# rust_test(
#     name = "user_of_cpp_api",
#     srcs = ["user_of_cpp_api.rs"],
#     harness = "libtest",
#     deps = [
#         ":cpp_api_rust",
#         "@crate_index//:googletest",
#     ],
# )

rust_library(
    name = "rust_api",
    srcs = ["rust_api.rs"],
    edition = "2024",
)

cpp_api_from_rust(
    name = "rust_api_cc",
    crate = ":rust_api",
)

cc_test(
    name = "user_of_rust_api",
    srcs = ["user_of_rust_api.cc"],
    deps = [
        ":rust_api_cc",
        "@abseil-cpp//absl/functional:any_invocable",
        "@googletest//:gtest_main",
    ],
)
