//! Native macOS Liquid Glass surfaces, hosted by SwiftUI above the Rust-rendered UI.

use egui::{Context, Id, Rect};
use std::{ffi::CString, sync::Arc};

fn rects_id() -> Id { Id::new("notmusic-native-glass-rects") }

#[repr(C)]
#[derive(Clone, Copy)]
struct GlassRect {
    x: f64,
    y: f64,
    width: f64,
    height: f64,
    radius: f64,
    opacity: f64,
    style: i32,
    visible: i32,
    group: u64,
    kind: i32,
    _reserved: i32,
    content: usize,
    font_size: f64,
    font_weight: i32,
    _reserved2: i32,
}

#[derive(Clone, Default)]
struct GlassFrame {
    rects: Vec<GlassRect>,
    strings: Vec<Arc<CString>>,
}

impl GlassFrame {
    fn keep_string(&mut self, value: &str) -> usize {
        let value = Arc::new(CString::new(value.replace('\0', "�")).unwrap_or_default());
        let pointer = value.as_ptr();
        self.strings.push(value);
        pointer as usize
    }
}

#[cfg(target_os = "macos")]
type SyncFn = unsafe extern "C" fn(*mut std::ffi::c_void, *const std::ffi::c_void, i32);

#[cfg(target_os = "macos")]
fn sync_fn() -> Option<SyncFn> {
    use std::sync::OnceLock;
    static SYNC: OnceLock<Option<SyncFn>> = OnceLock::new();
    *SYNC.get_or_init(|| unsafe {
        use std::ffi::{CString, c_char, c_void};
        unsafe extern "C" {
            fn dlopen(path: *const c_char, mode: i32) -> *mut c_void;
            fn dlsym(handle: *mut c_void, symbol: *const c_char) -> *mut c_void;
        }
        let executable = std::env::current_exe().ok()?;
        let parent = executable.parent()?;
        let library = if parent.file_name().is_some_and(|name| name == "MacOS") {
            parent.parent()?.join("Frameworks/libNotMusicGlass.dylib")
        } else {
            parent.join("libNotMusicGlass.dylib")
        };
        let path = CString::new(library.to_string_lossy().as_bytes()).ok()?;
        let handle = dlopen(path.as_ptr(), 2); // RTLD_NOW; retain the handle for process lifetime.
        if handle.is_null() { return None; }
        let symbol = CString::new("notmusic_glass_sync").ok()?;
        let address = dlsym(handle, symbol.as_ptr());
        if address.is_null() { None } else { Some(std::mem::transmute::<*mut c_void, SyncFn>(address)) }
    })
}

pub fn available() -> bool {
    #[cfg(target_os = "macos")]
    { sync_fn().is_some() }
    #[cfg(not(target_os = "macos"))]
    { false }
}

pub fn begin(ctx: &Context) {
    ctx.data_mut(|data| data.insert_temp(rects_id(), GlassFrame::default()));
}

/// style 0 is the stronger regular capsule; style 1 is the lighter clear button glass.
pub fn add(ctx: &Context, rect: Rect, radius: f32, style: i32) {
    add_faded(ctx, rect, radius, style, 1.0);
}

pub fn add_faded(ctx: &Context, rect: Rect, radius: f32, style: i32, opacity: f32) {
    add_faded_group(ctx, rect, radius, style, opacity, 0);
}

/// Add a material surface with a group ID so foreground cutouts can stay crisp above it.
pub fn add_group(ctx: &Context, rect: Rect, radius: f32, style: i32, group: u64) {
    add_faded_group(ctx, rect, radius, style, 1.0, group);
}

pub fn add_faded_group(ctx: &Context, rect: Rect, radius: f32, style: i32, opacity: f32, group: u64) {
    if opacity <= 0.005 { return; }
    if rect.width() <= 0.0 || rect.height() <= 0.0 { return; }
    ctx.data_mut(|data| {
        let mut glass = data.get_temp::<GlassFrame>(rects_id()).unwrap_or_default();
        glass.rects.push(GlassRect {
            x: rect.left() as f64,
            y: rect.top() as f64,
            width: rect.width() as f64,
            height: rect.height() as f64,
            radius: radius.max(0.0) as f64,
            opacity: opacity.clamp(0.0, 1.0) as f64,
            style,
            visible: 1,
            group,
            kind: 0,
            _reserved: 0,
            content: 0,
            font_size: 0.0,
            font_weight: 0,
            _reserved2: 0,
        });
        data.insert_temp(rects_id(), glass);
    });
}

/// Keep foreground glyphs/text crisp over a native glass surface in the matching group.
/// The Swift host masks this tiny region out of its frontmost blur/material layer.
pub fn keep_clear(ctx: &Context, rect: Rect, group: u64) {
    if rect.width() <= 0.0 || rect.height() <= 0.0 { return; }
    ctx.data_mut(|data| {
        let mut glass = data.get_temp::<GlassFrame>(rects_id()).unwrap_or_default();
        glass.rects.push(GlassRect {
            x: rect.left() as f64,
            y: rect.top() as f64,
            width: rect.width() as f64,
            height: rect.height() as f64,
            radius: (rect.height().min(rect.width()) * 0.18) as f64,
            opacity: 1.0,
            style: 0,
            visible: 1,
            group,
            kind: 1,
            _reserved: 0,
            content: 0,
            font_size: 0.0,
            font_weight: 0,
            _reserved2: 0,
        });
        data.insert_temp(rects_id(), glass);
    });
}

/// Mask only the actual text glyphs, rather than a rectangular label area.
pub fn keep_clear_text(ctx: &Context, rect: Rect, text: &str, size: f32, semibold: bool, group: u64) {
    if rect.width() <= 0.0 || rect.height() <= 0.0 || text.is_empty() { return; }
    ctx.data_mut(|data| {
        let mut glass = data.get_temp::<GlassFrame>(rects_id()).unwrap_or_default();
        let content = glass.keep_string(text);
        glass.rects.push(GlassRect {
            x: rect.left() as f64,
            y: rect.top() as f64,
            width: rect.width() as f64,
            height: rect.height() as f64,
            radius: 0.0,
            opacity: 1.0,
            style: 0,
            visible: 1,
            group,
            kind: 2,
            _reserved: 0,
            content,
            font_size: size as f64,
            font_weight: i32::from(semibold),
            _reserved2: 0,
        });
        data.insert_temp(rects_id(), glass);
    });
}

/// Mask a notMusic glyph by its PNG alpha channel; no rectangular button cutout.
pub fn keep_clear_icon(ctx: &Context, rect: Rect, asset: &str, group: u64) {
    if rect.width() <= 0.0 || rect.height() <= 0.0 { return; }
    ctx.data_mut(|data| {
        let mut glass = data.get_temp::<GlassFrame>(rects_id()).unwrap_or_default();
        let content = glass.keep_string(asset);
        glass.rects.push(GlassRect {
            x: rect.left() as f64,
            y: rect.top() as f64,
            width: rect.width() as f64,
            height: rect.height() as f64,
            radius: 0.0,
            opacity: 1.0,
            style: 0,
            visible: 1,
            group,
            kind: 3,
            _reserved: 0,
            content,
            font_size: 0.0,
            font_weight: 0,
            _reserved2: 0,
        });
        data.insert_temp(rects_id(), glass);
    });
}

pub fn sync(ctx: &Context, frame: &eframe::Frame) {
    #[cfg(target_os = "macos")]
    if let Some(call) = sync_fn() {
        use raw_window_handle::{HasWindowHandle, RawWindowHandle};
        let Ok(handle) = frame.window_handle() else { return };
        let RawWindowHandle::AppKit(window) = handle.as_raw() else { return };
        let glass = ctx.data(|data| data.get_temp::<GlassFrame>(rects_id())).unwrap_or_default();
        let pointer = if glass.rects.is_empty() { std::ptr::null() } else { glass.rects.as_ptr().cast() };
        unsafe { call(window.ns_view.as_ptr(), pointer, glass.rects.len() as i32) };
    }
}
