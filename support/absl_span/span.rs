// Part of the Crubit project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

//! Rust counterparts of C++ `absl::Span<T>`.
//!
//! These are added to the `absl` module of the bindings for `absl/types:span`, and are what Crubit
//! maps `absl::Span<T>` to:
//!
//! * `absl::Span<const T>` is `Span<'a, T>` (like `&'a [T]`) or `RawSpan<T>` (like `*const [T]`).
//! * `absl::Span<T>` is `SpanMut<'a, T>` (like `&'a mut [T]`) or `RawSpanMut<T>` (like `*mut [T]`).
//!
//! All four have the same layout as `absl::Span<T>`: a pointer followed by a length. They follow
//! C++ conventions for empty spans, which may have a null pointer, unlike Rust slices. This is
//! the inverse of `rs_std::SliceRef<T>`, which is a C++ type with Rust slice semantics.

use core::fmt;
use core::marker::PhantomData;
use core::ops::{Deref, DerefMut};
use core::ptr::{self, NonNull};

/// Returns a raw slice for the given pointer and length, which may use the C++ representation of
/// an empty span (a null pointer).
fn raw_slice<T>(ptr: *const T, len: usize) -> *const [T] {
    if len == 0 {
        // Rust slices must have a non-null (and aligned) pointer, even when empty.
        ptr::slice_from_raw_parts(NonNull::<T>::dangling().as_ptr(), 0)
    } else {
        ptr::slice_from_raw_parts(ptr, len)
    }
}

/// Returns the pointer and length of `slice`, using the C++ representation of an empty span (a
/// null pointer) if `slice` is empty.
fn raw_parts<T>(slice: *const [T]) -> (*const T, usize) {
    let len = slice.len();
    if len == 0 { (ptr::null(), 0) } else { (slice as *const T, len) }
}

/// A C++ `absl::Span<const T>` without a lifetime: the equivalent of `*const [T]`.
#[repr(C)]
pub struct RawSpan<T> {
    ptr: *const T,
    len: usize,
}

/// A C++ `absl::Span<T>` without a lifetime: the equivalent of `*mut [T]`.
#[repr(C)]
pub struct RawSpanMut<T> {
    ptr: *mut T,
    len: usize,
}

/// A C++ `absl::Span<const T>` which is live and immutable for the lifetime `'a`: the equivalent
/// of `&'a [T]`.
#[repr(C)]
pub struct Span<'a, T> {
    raw: RawSpan<T>,
    _marker: PhantomData<&'a [T]>,
}

/// A C++ `absl::Span<T>` which is live and exclusively borrowed for the lifetime `'a`: the
/// equivalent of `&'a mut [T]`.
#[repr(C)]
pub struct SpanMut<'a, T> {
    raw: RawSpanMut<T>,
    _marker: PhantomData<&'a mut [T]>,
}

// SAFETY: `Span<'a, T>` and `SpanMut<'a, T>` behave like `&'a [T]` and `&'a mut [T]`.
unsafe impl<T: Sync> Send for Span<'_, T> {}
unsafe impl<T: Sync> Sync for Span<'_, T> {}
unsafe impl<T: Send> Send for SpanMut<'_, T> {}
unsafe impl<T: Sync> Sync for SpanMut<'_, T> {}

impl<T> RawSpan<T> {
    /// Creates a span from a pointer and a length.
    pub const fn from_raw_parts(ptr: *const T, len: usize) -> Self {
        Self { ptr, len }
    }

    /// Returns the pointer to the first element. This may be null if the span is empty.
    pub const fn as_ptr(&self) -> *const T {
        self.ptr
    }

    /// Returns the number of elements in the span.
    pub const fn len(&self) -> usize {
        self.len
    }

    /// Returns `true` if the span is empty.
    pub const fn is_empty(&self) -> bool {
        self.len == 0
    }

    /// Returns the span as a raw slice. If the span is empty, the slice has a dangling (but
    /// non-null) pointer, as Rust requires.
    pub fn as_slice(&self) -> *const [T] {
        raw_slice(self.ptr, self.len)
    }

    /// Returns a span with the lifetime `'a`.
    ///
    /// # Safety
    ///
    /// For the lifetime `'a`, the span must be valid to dereference as a `&'a [T]`.
    pub unsafe fn as_live<'a>(self) -> Span<'a, T> {
        Span { raw: self, _marker: PhantomData }
    }
}

impl<T> RawSpanMut<T> {
    /// Creates a span from a pointer and a length.
    pub const fn from_raw_parts(ptr: *mut T, len: usize) -> Self {
        Self { ptr, len }
    }

    /// Returns the pointer to the first element. This may be null if the span is empty.
    pub const fn as_ptr(&self) -> *const T {
        self.ptr
    }

    /// Returns the pointer to the first element. This may be null if the span is empty.
    pub const fn as_mut_ptr(&self) -> *mut T {
        self.ptr
    }

    /// Returns the number of elements in the span.
    pub const fn len(&self) -> usize {
        self.len
    }

    /// Returns `true` if the span is empty.
    pub const fn is_empty(&self) -> bool {
        self.len == 0
    }

    /// Returns the span as a raw slice. If the span is empty, the slice has a dangling (but
    /// non-null) pointer, as Rust requires.
    pub fn as_slice(&self) -> *const [T] {
        raw_slice(self.ptr, self.len)
    }

    /// Returns the span as a raw mutable slice. If the span is empty, the slice has a dangling (but
    /// non-null) pointer, as Rust requires.
    pub fn as_mut_slice(&self) -> *mut [T] {
        raw_slice(self.ptr, self.len) as *mut [T]
    }

    /// Returns a span with the lifetime `'a`.
    ///
    /// # Safety
    ///
    /// For the lifetime `'a`, the span must be valid to dereference as a `&'a mut [T]`.
    pub unsafe fn as_live_mut<'a>(self) -> SpanMut<'a, T> {
        SpanMut { raw: self, _marker: PhantomData }
    }
}

impl<'a, T> Span<'a, T> {
    /// Returns the span without its lifetime.
    pub const fn as_raw(&self) -> RawSpan<T> {
        RawSpan { ptr: self.raw.ptr, len: self.raw.len }
    }

    /// Returns the span as a slice.
    pub fn as_slice(&self) -> &'a [T] {
        // SAFETY: `Span<'a, T>` is valid to dereference as a `&'a [T]`.
        unsafe { &*self.raw.as_slice() }
    }
}

impl<'a, T> SpanMut<'a, T> {
    /// Returns the span without its lifetime.
    pub const fn as_raw(&self) -> RawSpanMut<T> {
        RawSpanMut { ptr: self.raw.ptr, len: self.raw.len }
    }

    /// Returns the span as a slice.
    pub fn as_slice(&self) -> &[T] {
        // SAFETY: `SpanMut<'a, T>` is valid to dereference as a `&'a mut [T]`.
        unsafe { &*self.raw.as_slice() }
    }

    /// Returns the span as a mutable slice.
    pub fn as_mut_slice(&mut self) -> &mut [T] {
        // SAFETY: `SpanMut<'a, T>` is valid to dereference as a `&'a mut [T]`.
        unsafe { &mut *self.raw.as_mut_slice() }
    }

    /// Converts the span into a mutable slice with its full lifetime.
    pub fn into_mut_slice(self) -> &'a mut [T] {
        // SAFETY: `SpanMut<'a, T>` is valid to dereference as a `&'a mut [T]`.
        unsafe { &mut *self.raw.as_mut_slice() }
    }
}

// `RawSpan` and `Span` are `Copy` regardless of `T`, like `*const [T]` and `&[T]`.
impl<T> Clone for RawSpan<T> {
    fn clone(&self) -> Self {
        *self
    }
}
impl<T> Copy for RawSpan<T> {}
impl<T> Clone for RawSpanMut<T> {
    fn clone(&self) -> Self {
        *self
    }
}
impl<T> Copy for RawSpanMut<T> {}
impl<T> Clone for Span<'_, T> {
    fn clone(&self) -> Self {
        *self
    }
}
impl<T> Copy for Span<'_, T> {}

impl<T> Default for RawSpan<T> {
    fn default() -> Self {
        Self::from_raw_parts(ptr::null(), 0)
    }
}
impl<T> Default for RawSpanMut<T> {
    fn default() -> Self {
        Self::from_raw_parts(ptr::null_mut(), 0)
    }
}
impl<T> Default for Span<'_, T> {
    fn default() -> Self {
        Self { raw: RawSpan::default(), _marker: PhantomData }
    }
}
impl<T> Default for SpanMut<'_, T> {
    fn default() -> Self {
        Self { raw: RawSpanMut::default(), _marker: PhantomData }
    }
}

impl<T> From<*const [T]> for RawSpan<T> {
    fn from(slice: *const [T]) -> Self {
        let (ptr, len) = raw_parts(slice);
        Self::from_raw_parts(ptr, len)
    }
}
impl<T> From<*mut [T]> for RawSpanMut<T> {
    fn from(slice: *mut [T]) -> Self {
        let (ptr, len) = raw_parts(slice as *const [T]);
        Self::from_raw_parts(ptr as *mut T, len)
    }
}
impl<'a, T> From<&'a [T]> for Span<'a, T> {
    fn from(slice: &'a [T]) -> Self {
        Self { raw: RawSpan::from(slice as *const [T]), _marker: PhantomData }
    }
}
impl<'a, T> From<&'a mut [T]> for SpanMut<'a, T> {
    fn from(slice: &'a mut [T]) -> Self {
        Self { raw: RawSpanMut::from(slice as *mut [T]), _marker: PhantomData }
    }
}
impl<'a, T> From<SpanMut<'a, T>> for Span<'a, T> {
    fn from(span: SpanMut<'a, T>) -> Self {
        Self { raw: RawSpan::from(span.raw), _marker: PhantomData }
    }
}
impl<T> From<RawSpanMut<T>> for RawSpan<T> {
    fn from(span: RawSpanMut<T>) -> Self {
        Self::from_raw_parts(span.ptr, span.len)
    }
}
impl<T> From<Span<'_, T>> for RawSpan<T> {
    fn from(span: Span<'_, T>) -> Self {
        span.raw
    }
}
impl<T> From<SpanMut<'_, T>> for RawSpanMut<T> {
    fn from(span: SpanMut<'_, T>) -> Self {
        span.raw
    }
}

impl<T> Deref for Span<'_, T> {
    type Target = [T];
    fn deref(&self) -> &[T] {
        self.as_slice()
    }
}
impl<T> Deref for SpanMut<'_, T> {
    type Target = [T];
    fn deref(&self) -> &[T] {
        self.as_slice()
    }
}
impl<T> DerefMut for SpanMut<'_, T> {
    fn deref_mut(&mut self) -> &mut [T] {
        self.as_mut_slice()
    }
}

impl<T: fmt::Debug> fmt::Debug for Span<'_, T> {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        fmt::Debug::fmt(self.as_slice(), f)
    }
}
impl<T: fmt::Debug> fmt::Debug for SpanMut<'_, T> {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        fmt::Debug::fmt(self.as_slice(), f)
    }
}
impl<T> fmt::Debug for RawSpan<T> {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("RawSpan").field("ptr", &self.ptr).field("len", &self.len).finish()
    }
}
impl<T> fmt::Debug for RawSpanMut<T> {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("RawSpanMut").field("ptr", &self.ptr).field("len", &self.len).finish()
    }
}
