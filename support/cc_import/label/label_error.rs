// Copyright 2020 The Bazel Authors. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Vendored unmodified from rules_rust's `util/label/label_error.rs` at commit 44ffccb91c, to match the
// vendored `import_internal.rs`.

#[derive(Debug, PartialEq, Eq)]
pub struct LabelError(pub String);

impl std::fmt::Display for LabelError {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

impl std::error::Error for LabelError {
    fn description(&self) -> &str {
        &self.0
    }
}

impl From<String> for LabelError {
    fn from(msg: String) -> Self {
        Self(msg)
    }
}
