import AppKit
import SwiftUI
import Combine

@MainActor
final class NotchWindowController: NSWindowController {
    private let store: AgentStore
    private let panel: PanelState
    private var hostingView: PassthroughHostingView<RootView>?
    private var sinks: [AnyCancellable] = []
    private var hovered = false
    private var attentionSuppressed = false
    private var lastAttentionIds: Set<String> = []
    private let hoverShield = MouseHoverShield()
    private var globalClickMonitor: Any?
    private var globalMouseMoveMonitor: Any?
    private var localMouseMoveMonitor: Any?
    private var workspaceObserver: Any?

    private var topInset: CGFloat = 38
    private var notchWidth: CGFloat = 0
    private var isNotched: Bool = false

    init(store: AgentStore) {
        self.store = store

        let screen = ScreenGeometry.primary ?? NSScreen.main!
        let layout = ScreenGeometry.layout(for: screen)
        let collapsedW = layout.collapsedWidth
        self.panel = PanelState(
            collapsedBodyWidth: collapsedW,
            expandedBodyWidth: collapsedW,
            maxExpandedBodyHeight: max(120, screen.visibleFrame.height - 40)
        )

        switch layout {
        case .notched(let w, let h):
            isNotched = true
            notchWidth = w
            topInset = h
        case .fallback(let h):
            isNotched = false
            notchWidth = 0
            topInset = h
        }

        let window = NotchWindow()
        super.init(window: window)

        positionWindow(for: screen)

        let rootView = makeRootView()
        let hosting = PassthroughHostingView(rootView: rootView)
        if #available(macOS 13.0, *) {
            hosting.sizingOptions = []
        }
        hosting.frame = NSRect(origin: .zero, size: window.frame.size)
        hosting.autoresizingMask = [.width, .height]
        window.contentView = hosting
        hostingView = hosting
        updateHitShape()

        panel.contentHeight = PanelMetrics.contentHeight(
            forSessions: store.sessions.count,
            pendingCount: store.pendingPermissions.count
        )

        store.$sessions
            .receive(on: RunLoop.main)
            .sink { [weak self] sessions in
                guard let self else { return }
                self.panel.contentHeight = PanelMetrics.contentHeight(
                    forSessions: sessions.count,
                    pendingCount: self.store.pendingPermissions.count
                )
                self.updateHitShape()
                self.applyAttentionPolicy()
            }
            .store(in: &sinks)

        store.$pendingPermissions
            .receive(on: RunLoop.main)
            .sink { [weak self] pending in
                guard let self else { return }
                self.panel.contentHeight = PanelMetrics.contentHeight(
                    forSessions: self.store.sessions.count,
                    pendingCount: pending.count
                )
                self.updateHitShape()
                self.applyAttentionPolicy()
            }
            .store(in: &sinks)

        panel.$mode
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.recomputeExpansion()
                self.updateHitShape()
            }
            .store(in: &sinks)

        installGlobalClickMonitor()
        installMouseTracking()
        hoverShield.onSwallow = { [weak self] location in
            MainActor.assumeIsolated { self?.cursorEnteredShield(at: location) }
        }
        hoverShield.install()

        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.recomputeExpansion() }
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        if let m = globalClickMonitor { NSEvent.removeMonitor(m) }
        if let m = globalMouseMoveMonitor { NSEvent.removeMonitor(m) }
        if let m = localMouseMoveMonitor { NSEvent.removeMonitor(m) }
        if let o = workspaceObserver { NSWorkspace.shared.notificationCenter.removeObserver(o) }
    }

    func showOnScreen() {
        if let screen = ScreenGeometry.primary {
            positionWindow(for: screen)
        }
        window?.orderFrontRegardless()
    }

    func togglePanel() {
        guard let window else { return }
        if window.isVisible { window.orderOut(nil) } else { showOnScreen() }
    }

    private func positionWindow(for screen: NSScreen) {
        let width = panel.expandedBodyWidth
        let height = topInset + panel.maxBodyHeight
        let frame = ScreenGeometry.frame(for: screen, width: width, height: height)
        window?.setFrame(frame, display: true)
        hostingView?.frame = NSRect(origin: .zero, size: frame.size)
        updateHitShape()
    }

    private func makeRootView() -> RootView {
        RootView(
            store: store,
            panel: panel,
            topInset: topInset,
            notchWidth: notchWidth,
            isNotched: isNotched
        )
    }

    private func currentNotchShape() -> NotchPanelShape {
        NotchPanelShape(
            notchWidth: notchWidth,
            notchHeight: topInset,
            bodyWidth: panel.bodyWidth,
            bodyHeight: panel.bodyHeight,
            notchTopRadius: 6,
            notchBottomRadius: 14,
            bodyCornerRadius: 14
        )
    }

    private func updateHitShape() {
        hostingView?.updateHitShape(
            currentNotchShape(),
            isNotched: isNotched,
            bodyWidth: panel.bodyWidth,
            bodyHeight: panel.bodyHeight
        )
        updateHoverShieldRegion()
    }

    private func updateHoverShieldRegion() {
        guard let window, let screenHeight = NSScreen.screens.first?.frame.height else { return }
        let frame = window.frame
        let minBodyW = notchWidth + 2 * 14
        let bw = isNotched ? max(panel.bodyWidth, minBodyW) : panel.bodyWidth
        let contentHeight = topInset + max(panel.bodyHeight, 0)
        let region = CGRect(
            x: frame.midX - bw / 2,
            y: screenHeight - frame.maxY,
            width: bw,
            height: contentHeight
        )
        hoverShield.updateRegion(region)
    }

    private func cursorEnteredShield(at location: CGPoint) {
        guard let window, let screenHeight = NSScreen.screens.first?.frame.height else { return }
        let frame = window.frame
        let point = NSPoint(x: location.x - frame.minX, y: location.y - (screenHeight - frame.maxY))
        panel.hoverPoint = point
        handleHoverChange(inside: true)
        HoverCursor.shared.apply()
    }

    private func handleHoverChange(inside: Bool) {
        if hovered != inside {
            hovered = inside
            recomputeExpansion()
        }
    }

    private func applyAttentionPolicy() {
        let attentionIds = Set(store.sessions.filter { store.effectivelyNeedsAttention($0) }.map(\.id))
        let newOnes = attentionIds.subtracting(lastAttentionIds)
        if !newOnes.isEmpty { attentionSuppressed = false }
        lastAttentionIds = attentionIds
        recomputeExpansion()
    }

    private func userClickedOutside() {
        if panel.mode != .sessions { panel.mode = .sessions }
        if panel.expanded {
            attentionSuppressed = true
            recomputeExpansion()
        }
    }

    private func recomputeExpansion() {
        let attentionDrivenExpand = store.autoExpandOnAttention
            && store.anyNeedsAttention
            && !attentionSuppressed
            && !userIsOnAttentionTerminal()
        let shouldExpand = hovered || panel.mode != .sessions || attentionDrivenExpand
        if panel.expanded != shouldExpand {
            panel.expanded = shouldExpand
            updateHitShape()
        }
    }

    private func userIsOnAttentionTerminal() -> Bool {
        guard let front = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else { return false }
        return store.sessions
            .filter { store.effectivelyNeedsAttention($0) }
            .contains { terminalMatches($0.termProgram, bundleId: front) }
    }

    private func terminalMatches(_ termProgram: String?, bundleId: String) -> Bool {
        guard let termProgram else { return false }
        let id = bundleId.lowercased()
        switch termProgram {
        case "Apple_Terminal": return id == "com.apple.terminal"
        case "iTerm.app": return id.contains("iterm")
        case "WarpTerminal": return id.contains("warp")
        case "vscode": return id.contains("vscode") || id.contains("com.microsoft.vscode")
        case "ghostty": return id.contains("ghostty")
        case "Hyper": return id.contains("hyper")
        case "Tabby": return id.contains("tabby")
        case "kitty": return id.contains("kitty")
        case "alacritty", "Alacritty": return id.contains("alacritty")
        default: return false
        }
    }

    private func installGlobalClickMonitor() {
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in self?.userClickedOutside() }
        }
    }

    private func installMouseTracking() {
        let syncHandler: (NSEvent) -> Void = { [weak self] _ in
            MainActor.assumeIsolated { self?.updateCursorTracking() }
        }
        globalMouseMoveMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved, handler: syncHandler)
        localMouseMoveMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { event in
            syncHandler(event)
            return event
        }
        updateCursorTracking()
    }

    private func updateCursorTracking() {
        panel.hoverPoint = nil
        HoverCursor.shared.clear()
        handleHoverChange(inside: false)
    }
}

final class PassthroughHostingView<Content: View>: NSHostingView<Content> {
    private var hitShape: NotchPanelShape?
    private var isNotched = true
    private var fallbackBodyWidth: CGFloat = 0
    private var fallbackBodyHeight: CGFloat = 0

    func updateHitShape(_ shape: NotchPanelShape, isNotched: Bool, bodyWidth: CGFloat, bodyHeight: CGFloat) {
        self.hitShape = shape
        self.isNotched = isNotched
        self.fallbackBodyWidth = bodyWidth
        self.fallbackBodyHeight = bodyHeight
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        guard interactiveRegionContains(local) else { return nil }
        return super.hitTest(point) ?? self
    }

    private func interactiveRegionContains(_ p: NSPoint) -> Bool {
        let y = isFlipped ? p.y : bounds.height - p.y
        let testPoint = NSPoint(x: p.x, y: y)
        if isNotched, let hitShape {
            return hitShape.path(in: bounds).contains(testPoint)
        }
        let w = fallbackBodyWidth
        let h = fallbackBodyHeight + 6
        let rect = NSRect(x: bounds.midX - w / 2, y: 0, width: w, height: h)
        return rect.contains(testPoint)
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
