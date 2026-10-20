// Part of the Crubit project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "greeter.h"

#include <string>
#include <vector>

#include "absl/strings/str_cat.h"
#include "absl/time/time.h"

std::string Greet(const std::string& name) {
  return absl::StrCat("Hello, ", name, "!");
}

std::vector<int> Range(int n) {
  std::vector<int> result;
  for (int i = 0; i < n; ++i) result.push_back(i);
  return result;
}

absl::Duration Timeout() { return absl::Seconds(5); }
