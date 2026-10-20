// Part of the Crubit project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#[unsafe(no_mangle)]
pub extern "C" fn run_rust_app() -> i32 {
    let name = cc_std::std::string_wrapper::from("crubit");
    // `Greet` takes a `const std::string&`, which Crubit binds as a pointer.
    // SAFETY: `name` is a valid `std::string` for the duration of the call.
    let greeting =
        unsafe { greeter_rs::Greet(name.as_void_ptr() as *const cc_std::std::string) };
    assert_eq!(greeting.to_str(), Ok("Hello, crubit!"));
    println!("{}", greeting.to_str().unwrap());

    let range = greeter_rs::Range(3);
    assert_eq!(range.len(), 3);
    0
}
