# Part of the Crubit project, under the Apache License v2.0 with LLVM
# Exceptions. See /LICENSE for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

"""Utility module for sharing logic between rules and aspects that generate Rust bindings from C++.
"""

load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")

def escape_cpp_target_name(package_name, crate_name):
    """Produce a valid crate name from the label of the cc_library (or other C++ library-like target).

    Args:
        package_name: (string) Bazel package of cc_library target.
        crate_name: (string) name of the cc_library target.

    Returns:
        string: escaped crate name
    """

    # Crubit generates assertions with `::core`, which would resolve to current crate, if current
    # crate (i.e., cc_library) is named 'core'.
    if crate_name == "core":
        _, _, last_path_component = package_name.rpartition("/")
        crate_name = "core_" + last_path_component
    elif crate_name[0].isdigit():
        crate_name = "n" + crate_name

    # b/216587072: Sync the escaping logic with bazel_rules/rules_rust/rust/private:utils.bzl's
    # encode_label_as_crate_name. Currently, the encoding contains a (escaped and hence longer) copy
    # of both the package name _and_ the target name, which causes "File name too long" error.
    return "".join([char if char.isalnum() else "_" for char in crate_name.elems()])

def _get_hdrs_command_line(hdrs, system_hdr_paths):
    return ["--public_headers=" + ",".join([x.path for x in hdrs] + system_hdr_paths)]

def _get_extra_rs_srcs_command_line(extra_rs_srcs):
    extra_rs_src_info = []
    for (file, ns_path) in extra_rs_srcs:
        if ns_path:
            extra_rs_src_info.append(file.path + "=" + ns_path)
        else:
            extra_rs_src_info.append(file.path)
    return ["--extra_rs_srcs=" + ",".join(extra_rs_src_info)]

def _get_unstable_rust_features_command_line(unstable_rust_features):
    if not unstable_rust_features:
        return []
    return ["--unstable_rust_features=" + ",".join(unstable_rust_features)]

def _get_extra_cpp_srcs_command_line(extra_cpp_srcs):
    if not extra_cpp_srcs:
        return []
    return ["--extra_cpp_srcs=" + ",".join([x.path for x in extra_cpp_srcs])]

def _escape_param_file_arg(arg):
    # See `ExpandParamfiles` in rs_bindings_from_cc/cmdline.cc: arguments are newline-separated, and
    # a backslash escapes the following character.
    return arg.replace("\\", "\\\\").replace("\n", "\\\n")

def generate_bindings(
        ctx,
        attr,
        cc_toolchain,
        feature_configuration,
        compilation_context,
        public_hdrs,
        system_public_hdr_paths,
        header_includes,
        action_inputs,
        target_args,
        extra_rs_srcs,
        extra_cpp_srcs,
        unstable_rust_features,
        extra_rs_bindings_from_cc_cli_flags):
    """Runs the bindings generator.

    Args:
      ctx: The rule context.
      attr: The current rule's attributes.
      cc_toolchain: The cc_toolchain.
      feature_configuration: The feature configuration.
      compilation_context: The compilation context for this action.
      public_hdrs: A list of headers to be passed to the tool via the "--public_headers" flag.
      system_public_hdr_paths: A list of absolute paths of additional public headers that are not
        Bazel files (e.g. standard library headers in the macOS SDK).
      header_includes: A list of flags to be passed to the command line with "-include".
      action_inputs: A depset of inputs to the bindings generating action.
      target_args: A depset of strings, each one representing mapping of target to
                        its per-target arguments (headers, features, crate name) in json format.
      extra_rs_srcs: A list of extra source file and module path pairs to add.
      extra_cpp_srcs: A list of extra C++ source files to add.
      unstable_rust_features: A list of unstable rustc features to enable.
      extra_rs_bindings_from_cc_cli_flags: CLI flags to be passed to `rs_bindings_from_cc`.

    Returns:
      tuple(cc_output, rs_output, namespaces_output, error_report_output): The generated source files.
    """
    crate_name = escape_cpp_target_name(ctx.label.package, ctx.label.name)
    cc_output = ctx.actions.declare_file(crate_name + "_rust_api_impl.cc")
    rs_output = ctx.actions.declare_file(crate_name + "_rust_api.rs")
    namespaces_output = ctx.actions.declare_file(crate_name + "_namespaces.json")
    error_report_output = None

    verbose_log_flags = []

    rs_bindings_from_cc_flags = verbose_log_flags + [
        "--target=" + str(ctx.label),
        "--rs_out",
        rs_output.path,
        "--cc_out",
        cc_output.path,
        "--namespaces_out",
        namespaces_output.path,
        "--crubit_support_path_format",
        "\"support/{header}\"",
        "--clang_format_exe_path",
        ctx.file._clang_format.path,
        "--rustfmt_exe_path",
        ctx.file._rustfmt.path,
        "--rustfmt_config_path",
        ctx.file._rustfmt_cfg.path,
    ]

    if ctx.attr._lazy_import_alien_decls[BuildSettingInfo].value:
        rs_bindings_from_cc_flags.append("--lazy_import_alien_decls")

    if ctx.attr._generate_error_report[BuildSettingInfo].value:
        error_report_output = ctx.actions.declare_file(crate_name + "_rust_api_error_report.json")
        rs_bindings_from_cc_flags += [
            "--error_report_out",
            error_report_output.path,
        ]

    toolchain = ctx.toolchains["@rules_crubit//rs_bindings_from_cc/bazel_support:toolchain_type"]
    if toolchain == None:
        # Fail at action execution time.
        # Note: we can't just keep going with an error shell script as the binary,
        # because the Crubit analysis phase is likely not configured on this platform.
        # So instead, we directly error out on actions producing the output files.
        ctx.actions.run_shell(
            command = (
                "echo 'Crubit (rs_bindings_from_cc) is not available on this platform.\n" + "To debug, rerun with --toolchain_resolution_debug=@rules_crubit//rs_bindings_from_cc/bazel_support:toolchain_type'" + " && false"
            ),
            outputs = [cc_output, rs_output, namespaces_output] + ([error_report_output] if error_report_output != None else []),
            mnemonic = "RustBindingsFromCcUnsupported",
        )
        return (cc_output, rs_output, namespaces_output, error_report_output)

    rs_bindings_from_cc_tool = toolchain.rs_bindings_from_cc_toolchain_info.binary

    if ctx.attr._template_blocklist_path_regex[BuildSettingInfo].value:
        rs_bindings_from_cc_flags += [
            "--template_blocklist_path_regex",
            "|".join(ctx.attr._template_blocklist_path_regex[BuildSettingInfo].value),
        ]

    # Order any overrides *after* defaults set above.
    rs_bindings_from_cc_flags += extra_rs_bindings_from_cc_cli_flags

    # The C++ toolchain's own compile flags already set up the standard library and builtin header
    # search paths. (Internally, these were added explicitly by indexing into
    # `cc_toolchain.built_in_include_directories`, which depends on that toolchain's layout.)
    system_include_directories = compilation_context.system_includes

    local_defines = []
    for d in getattr(attr, "local_defines", []):
        local_defines.append(ctx.expand_make_variables("local_defines", d, {}))

    variables_extension = {
        "rs_bindings_from_cc_tool": rs_bindings_from_cc_tool.path,
        "rs_bindings_from_cc_flags": rs_bindings_from_cc_flags + _get_hdrs_command_line(public_hdrs, system_public_hdr_paths) + _get_extra_rs_srcs_command_line(extra_rs_srcs) + _get_unstable_rust_features_command_line(unstable_rust_features) + _get_extra_cpp_srcs_command_line(extra_cpp_srcs),
        "target_args": target_args,
    }
    variables = cc_common.create_compile_variables(
        feature_configuration = feature_configuration,
        cc_toolchain = cc_toolchain,
        system_include_directories = system_include_directories,
        include_directories = compilation_context.includes,
        quote_include_directories = compilation_context.quote_includes,
        # TODO(b/571633624): Remove this intermediate filter once Crubit handles
        # driver diagnostics / flag filtering in rs_bindings_from_cc and the
        # release stabilizes.
        user_compile_flags = [
            f
            for f in (
                ctx.fragments.cpp.copts +
                ctx.fragments.cpp.cxxopts +
                header_includes + (
                    attr.copts if hasattr(attr, "copts") else []
                )
            )
            if not f.startswith("-Xactionanalyzer")
        ],
        preprocessor_defines = depset(
            local_defines,
            transitive = [compilation_context.defines],
        ),
        variables_extension = variables_extension,
    )

    # Run the `rs_bindings_from_cc` to generate the _rust_api_impl.cc and _rust_api.rs files.
    #
    # Internally, the C++ toolchain defines an `rs_bindings_from_cc` action config, so this can be
    # a `cc_common.create_compile_action`. Off-the-shelf OSS C++ toolchains have no such action, so
    # instead we take the toolchain's C++ compile flags and invoke `rs_bindings_from_cc` directly.
    compile_flags = cc_common.get_memory_inefficient_command_line(
        feature_configuration = feature_configuration,
        action_name = ACTION_NAMES.cpp_compile,
        variables = variables,
    )
    compile_env = cc_common.get_environment_variables(
        feature_configuration = feature_configuration,
        action_name = ACTION_NAMES.cpp_compile,
        variables = variables,
    )
    args = ctx.actions.args()

    # `target_args` can be large (e.g. it lists every standard library header), so pass the
    # arguments via a param file, escaped the way `rs_bindings_from_cc` reads them.
    args.use_param_file("@%s", use_always = True)
    args.set_param_file_format("multiline")
    args.add_all(["--driver_path=" + cc_toolchain.compiler_executable], map_each = _escape_param_file_arg)
    args.add_all(variables_extension["rs_bindings_from_cc_flags"], map_each = _escape_param_file_arg)
    args.add_all(target_args, before_each = "--target_to_arg", map_each = _escape_param_file_arg)
    args.add("--")
    args.add_all(compile_flags, map_each = _escape_param_file_arg)
    ctx.actions.run(
        executable = rs_bindings_from_cc_tool,
        arguments = [args],
        inputs = depset(
            direct = public_hdrs + ctx.files._rustfmt_cfg + extra_cpp_srcs,
            transitive = [action_inputs, compilation_context.headers, cc_toolchain.all_files],
        ),
        tools = [ctx.executable._clang_format, ctx.executable._rustfmt],
        outputs = [x for x in [cc_output, rs_output, namespaces_output, error_report_output] if x != None],
        env = compile_env,
        # Same mnemonic as the internal `rs_bindings_from_cc` compile action this replaces.
        mnemonic = "CppHeaderAnalysis",
        progress_message = "Generating Rust bindings for C++: %{label}",
        toolchain = "@rules_crubit//rs_bindings_from_cc/bazel_support:toolchain_type",
    )
    return (cc_output, rs_output, namespaces_output, error_report_output)
