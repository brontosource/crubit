// Part of the Crubit project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "rs_bindings_from_cc/test/templates/extern_definition/extern_definition.h"

namespace extern_definition {

// The explicit instantiation promised by the `extern template` declaration in
// the header (as libc++ provides for `collate<char>`). Without it, unoptimized
// builds fail to link because the members are never emitted.
template class MyTemplate<int>;

}  // namespace extern_definition
