load(
    "@rules_rust//rust:defs.bzl",
    "rust_library",
    "rust_proc_macro",
)
load("//common:crubit_wrapper_macros_oss.bzl", "crubit_rust_test")

package(default_applicable_licenses = ["//:license"])

rust_proc_macro(
    name = "cc_import",
    srcs = [
        "cc_import.rs",
    ],
    compatible_with = ["//buildenv/target:non_prod"],
    visibility = [
        "//visibility:public",
    ],
    deps = [
        ":cc_import_internal",
        "@crate_index//:proc-macro2",
        "@crate_index//:syn",  # v1
    ],
)

# Vendored from rules_rust, which no longer provides it. See import_internal.rs.
rust_library(
    name = "import_internal",
    srcs = ["import_internal.rs"],
    compatible_with = ["//buildenv/target:non_prod"],
    edition = "2018",
    deps = [
        ":label",
        "@crate_index//:aho-corasick",
        "@crate_index//:proc-macro2",
        "@crate_index//:quote",
        "@crate_index//:syn",
    ],
)

# Vendored from rules_rust for `import_internal`. See label/label.rs.
rust_library(
    name = "label",
    srcs = [
        "label/label.rs",
        "label/label_error.rs",
    ],
    compatible_with = ["//buildenv/target:non_prod"],
    edition = "2018",
)

rust_library(
    name = "cc_import_internal",
    srcs = [
        "cc_import_internal.rs",
    ],
    compatible_with = ["//buildenv/target:non_prod"],
    edition = "2024",
    deps = [
        ":merged_namespaces",
        "@crate_index//:proc-macro2",
        "@crate_index//:quote",  # v1
        "@crate_index//:serde_json",  # v1
        "@crate_index//:syn",  # v1
        ":import_internal",
    ],
)

rust_library(
    name = "merged_namespaces",
    srcs = ["merged_namespaces.rs"],
    compatible_with = ["//buildenv/target:non_prod"],
    edition = "2024",
    deps = [
        "@crate_index//:proc-macro2",
        "@crate_index//:quote",  # v1
        "@crate_index//:serde",  # v1
        "@crate_index//:serde_json",  # v1
        "@crate_index//:syn",  # v1
        ":import_internal",
    ],
)

crubit_rust_test(
    name = "merged_namespaces_test",
    crate = "merged_namespaces",
    deps = [
        "//common:token_stream_matchers",
        "@crate_index//:googletest",
    ],
)
