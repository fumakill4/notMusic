import AppKit
import SwiftUI

private struct NativeGlassRectRaw {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var radius: Double
    var opacity: Double
    var style: Int32
    var visible: Int32
    var group: UInt64
    var kind: Int32
    var reserved: Int32
    var content: UnsafePointer<CChar>?
    var fontSize: Double
    var fontWeight: Int32
    var reserved2: Int32
}

private struct NativeGlassRect {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var radius: Double
    var opacity: Double
    var style: Int32
    var visible: Int32
    var group: UInt64
    var kind: Int32
    var reserved: Int32
    var content: String?
    var fontSize: Double
    var fontWeight: Int32

    init(_ raw: NativeGlassRectRaw) {
        x = raw.x; y = raw.y; width = raw.width; height = raw.height
        radius = raw.radius; opacity = raw.opacity; style = raw.style
        visible = raw.visible; group = raw.group; kind = raw.kind
        reserved = raw.reserved
        content = raw.content.map { String(cString: $0) }
        fontSize = raw.fontSize; fontWeight = raw.fontWeight
    }
}

@MainActor
private final class GlassState: ObservableObject {
    @Published var rects: [NativeGlassRect] = []
}

private struct GlassOverlay: View {
    @ObservedObject var state: GlassState

    private var surfaces: [NativeGlassRect] { state.rects.filter { $0.kind == 0 && $0.visible != 0 } }
    private var cutouts: [NativeGlassRect] { state.rects.filter { (1...3).contains($0.kind) && $0.visible != 0 } }

    private func glyphImage(_ name: String) -> NSImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "GlassGlyphs") else { return nil }
        return NSImage(contentsOf: url)
    }

    @ViewBuilder
    private func foregroundMaskItem(_ hole: NativeGlassRect, in item: NativeGlassRect) -> some View {
        let center = CGPoint(x: hole.x - item.x + hole.width / 2,
                             y: hole.y - item.y + hole.height / 2)
        if hole.kind == 1 {
            RoundedRectangle(cornerRadius: hole.radius, style: .continuous)
                .fill(.black)
                .frame(width: hole.width, height: hole.height)
                .position(center)
        } else if hole.kind == 2, let text = hole.content {
            Text(text)
                .font(.system(size: hole.fontSize, weight: hole.fontWeight == 1 ? .semibold : .regular))
                .lineLimit(1)
                .padding(2)
                .frame(width: hole.width, height: hole.height, alignment: .topLeading)
                .foregroundStyle(.black)
                .position(center)
        } else if hole.kind == 3, let name = hole.content, let image = glyphImage(name) {
            Image(nsImage: image)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .foregroundStyle(.black)
                .frame(width: hole.width, height: hole.height)
                .position(center)
        }
    }

    private func foregroundMask(for item: NativeGlassRect) -> some View {
        let matching = cutouts.filter { $0.group == item.group }
        return GeometryReader { _ in
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: item.radius, style: .continuous).fill(.white)
                ForEach(Array(matching.enumerated()), id: \.offset) { _, hole in
                    foregroundMaskItem(hole, in: item)
                }
            }
            .compositingGroup()
            .luminanceToAlpha()
        }
        .frame(width: item.width, height: item.height)
    }

    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .topLeading) {
                ForEach(Array(surfaces.enumerated()), id: \.offset) { _, item in
                    let shape = AnyShape(RoundedRectangle(cornerRadius: item.radius, style: .continuous))
                    if #available(macOS 26.0, *) {
                        shape.fill(.clear)
                            .glassEffect(item.style == 0 ? .regular : .clear, in: shape)
                            .overlay(shape.stroke(.white.opacity(item.style == 0 ? 0.20 : 0.26), lineWidth: 0.7))
                            .opacity(item.opacity * (item.style == 0 ? 0.68 : 0.50))
                            .mask { foregroundMask(for: item) }
                            .frame(width: item.width, height: item.height)
                            .position(x: item.x + item.width / 2, y: item.y + item.height / 2)
                    } else {
                        shape.fill(.ultraThinMaterial)
                            .overlay(shape.stroke(.white.opacity(0.20), lineWidth: 0.7))
                            .opacity(item.opacity * 0.58)
                            .mask { foregroundMask(for: item) }
                            .frame(width: item.width, height: item.height)
                            .position(x: item.x + item.width / 2, y: item.y + item.height / 2)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

@MainActor
private final class PassthroughHostingView: NSHostingView<GlassOverlay> {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

@MainActor
private final class GlassHost {
    let state = GlassState()
    let view: PassthroughHostingView

    init(contentView: NSView) {
        view = PassthroughHostingView(rootView: GlassOverlay(state: state))
        view.frame = contentView.bounds
        view.autoresizingMask = [.width, .height]
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        contentView.addSubview(view, positioned: .above, relativeTo: nil)
    }
}

@MainActor
private var hosts: [ObjectIdentifier: GlassHost] = [:]

@_cdecl("notmusic_glass_sync")
public func notmusicGlassSync(
    _ viewPointer: UnsafeMutableRawPointer,
    _ rectsRaw: UnsafeRawPointer?,
    _ count: Int32
) {
    MainActor.assumeIsolated {
        let sourceView = Unmanaged<NSView>.fromOpaque(viewPointer).takeUnretainedValue()
        guard let window = sourceView.window, let contentView = window.contentView else { return }
        // Extend the app content under the titlebar so macOS doesn't paint a separate
        // dark title strip above the app's own background.
        window.styleMask.insert(.fullSizeContentView)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.titlebarSeparatorStyle = .none
        let key = ObjectIdentifier(window)
        let host = hosts[key] ?? GlassHost(contentView: contentView)
        hosts[key] = host
        host.view.frame = contentView.bounds
        host.view.isHidden = count <= 0
        guard count > 0, let rectsRaw else {
            host.state.rects = []
            return
        }
        let rectsPointer = rectsRaw.assumingMemoryBound(to: NativeGlassRectRaw.self)
        host.state.rects = (0..<Int(count)).map { index in
            var item = NativeGlassRect(rectsPointer[index])
            // egui reports top-origin points in its renderer view. AppKit views can
            // use either origin convention, so convert through the actual view tree
            // instead of assuming the window content and renderer share an origin.
            let sourceY = sourceView.isFlipped
                ? item.y
                : Double(sourceView.bounds.height) - item.y - item.height
            let sourceRect = NSRect(x: item.x, y: sourceY, width: item.width, height: item.height)
            let converted = sourceView.convert(sourceRect, to: host.view)
            // SwiftUI positions from the top edge; convert according to the host
            // view's actual flipped-coordinate convention.
            item.x = converted.origin.x
            item.y = host.view.isFlipped
                ? converted.origin.y
                : Double(host.view.bounds.height - converted.maxY)
            item.width = converted.width
            item.height = converted.height
            return item
        }
    }
}
