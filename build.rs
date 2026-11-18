// Embed the app icon into the Windows executable (Explorer, taskbar, shortcuts).
fn main() {
    println!("cargo:rerun-if-changed=assets/icon/icon.ico");
    theme_covers();
    native_glass();
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() == Ok("windows") {
        winresource::WindowsResource::new()
            .set_icon("assets/icon/icon.ico")
            .set_manifest(MANIFEST)
            .compile()
            .expect("failed to embed Windows icon");
    }
}

/// Compile the small SwiftUI Liquid Glass host used by the macOS Rust UI.
fn native_glass() {
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() != Ok("macos")
        || !std::env::var("HOST").is_ok_and(|host| host.contains("apple-darwin"))
    {
        return;
    }
    println!("cargo:rerun-if-changed=macos/NotMusicGlass.swift");
    let target = std::env::var("TARGET").unwrap_or_default();
    let arch = if target.starts_with("aarch64-") { "arm64" } else { "x86_64" };
    let out = std::path::PathBuf::from(std::env::var("OUT_DIR").expect("OUT_DIR"));
    let dylib = out.join("libNotMusicGlass.dylib");
    let status = std::process::Command::new("swiftc")
        .args([
            "-emit-library", "-O", "-module-name", "NotMusicGlass",
            "-target", &format!("{arch}-apple-macosx13.0"),
            "-framework", "AppKit", "-framework", "SwiftUI",
            "-Xlinker", "-install_name", "-Xlinker", "@rpath/libNotMusicGlass.dylib",
            "macos/NotMusicGlass.swift", "-o",
        ])
        .arg(&dylib)
        .status()
        .expect("Swift compiler is required to build the native macOS glass host");
    assert!(status.success(), "failed to compile the SwiftUI Liquid Glass host");
    // Keep a dev copy next to the Rust executable; bundle.sh also copies this dylib
    // into NotMusic.app/Contents/Frameworks for the packaged app.
    if let Some(profile_dir) = out.ancestors().nth(3) {
        let _ = std::fs::copy(&dylib, profile_dir.join("libNotMusicGlass.dylib"));
    }
}

// The segment heap returns freed memory to the OS far more readily than the default
// NT heap, which keeps the resident footprint down after bursts (images, JSON).
const MANIFEST: &str = r#"<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
  <application xmlns="urn:schemas-microsoft-com:asm.v3">
    <windowsSettings>
      <heapType xmlns="http://schemas.microsoft.com/SMI/2020/WindowsSettings">SegmentHeap</heapType>
    </windowsSettings>
  </application>
</assembly>
"#;

// Embed every theme preset's cover thumbnail (assets/themes/covers/<id>.jpg) as a
// table the settings page looks up by preset id.
fn theme_covers() {
    let dir = std::path::Path::new(&std::env::var("CARGO_MANIFEST_DIR").unwrap()).join("assets/themes/covers");
    println!("cargo:rerun-if-changed={}", dir.display());
    let mut entries: Vec<_> = std::fs::read_dir(&dir)
        .map(|rd| rd.filter_map(|e| e.ok()).map(|e| e.path()).filter(|p| p.extension().is_some_and(|x| x == "jpg")).collect())
        .unwrap_or_default();
    entries.sort();
    let mut out = String::from("&[\n");
    for p in entries {
        let id = p.file_stem().unwrap().to_string_lossy();
        out += &format!("    ({id:?}, include_bytes!({:?}).as_slice()),\n", p.display().to_string());
    }
    out += "]\n";
    std::fs::write(std::path::Path::new(&std::env::var("OUT_DIR").unwrap()).join("theme_covers.rs"), out).unwrap();
}
