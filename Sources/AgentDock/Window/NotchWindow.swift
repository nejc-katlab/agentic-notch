import AppKit

final class NotchWindow: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 22),
            styleMask: [.borderless, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered, defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        acceptsMouseMovedEvents = true
        hasShadow = false
        isFloatingPanel = true
        isMovable = false
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = true
        level = NSWindow.Level(Int(CGShieldingWindowLevel()) - 1)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        animationBehavior = .none
        isReleasedWhenClosed = false
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class MouseHoverShield: @unchecked Sendable {
    private var region = CGRect.zero
    private let lock = NSLock()
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var thread: Thread?
    private var runLoop: CFRunLoop?
    var onSwallow: (() -> Void)?

    func fireSwallow() {
        guard let onSwallow else { return }
        DispatchQueue.main.async { onSwallow() }
    }

    func updateRegion(_ r: CGRect) {
        lock.lock(); region = r; lock.unlock()
    }

    func contains(_ p: CGPoint) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return region.contains(p)
    }

    func reenable() {
        if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
    }

    @discardableResult
    func install() -> Bool {
        guard AXIsProcessTrusted() else {
            let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(opts)
            return false
        }
        let thread = Thread { [weak self] in
            guard let self else { return }
            let mask: CGEventMask = (1 << CGEventType.mouseMoved.rawValue)
            let selfPtr = Unmanaged.passUnretained(self).toOpaque()
            guard let tap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: mask,
                callback: mouseHoverShieldCallback,
                userInfo: selfPtr
            ) else {
                return
            }
            let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)!
            self.tap = tap
            self.source = source
            self.runLoop = CFRunLoopGetCurrent()
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            CFRunLoopRun()
        }
        thread.name = "MouseHoverShield"
        thread.qualityOfService = .userInteractive
        self.thread = thread
        thread.start()
        return true
    }

    deinit {
        if let tap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let runLoop {
            if let source { CFRunLoopRemoveSource(runLoop, source, .commonModes) }
            CFRunLoopStop(runLoop)
        }
    }
}

private func mouseHoverShieldCallback(
    _ proxy: CGEventTapProxy,
    _ type: CGEventType,
    _ event: CGEvent,
    _ userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let shield = Unmanaged<MouseHoverShield>.fromOpaque(userInfo).takeUnretainedValue()

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        shield.reenable()
        return Unmanaged.passUnretained(event)
    }
    if shield.contains(event.location) {
        shield.fireSwallow()
        return nil
    }
    return Unmanaged.passUnretained(event)
}
