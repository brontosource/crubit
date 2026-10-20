// Part of the Crubit project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "rs_bindings_from_cc/test/function/special_naming/special_naming.h"

int llvm_no_mangle_marker() { return 42; }

int asm_name_with_dollar_sign() { return 42; }

// Defines the `my_asm_conflict_func` symbol (via the `__asm__` label), on every
// platform. (An `extern "C"` function named `my_asm_conflict_func` would be
// `_my_asm_conflict_func` on platforms with a user label prefix, like macOS.)
SimpleStruct my_asm_conflict_func1() { return SimpleStruct{42}; }

extern "C" int name_conflict_when_thunk_normally_unnecessary(int x) {
  return x;
}

#if !IS_EMPTY(__USER_LABEL_PREFIX__)
// With a user label prefix (e.g. on macOS), the `__asm__` name of
// `name_conflict_when_thunk_normally_unnecessary_l` is not the symbol of
// `name_conflict_when_thunk_normally_unnecessary`, so define it separately,
// with the same behavior.
int name_conflict_when_thunk_normally_unnecessary_l(int x, int /*y*/) {
  return name_conflict_when_thunk_normally_unnecessary(x);
}
#endif
