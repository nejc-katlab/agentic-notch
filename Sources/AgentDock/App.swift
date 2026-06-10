import AppKit
import Darwin
import Foundation

typealias CGSConnectionID = UInt32

@_silgen_name("CGSMainConnectionID")
func CGSMainConnectionID() -> CGSConnectionID

@_silgen_name("CGSSetConnectionProperty")
func CGSSetConnectionProperty(
    _ cid: CGSConnectionID,
    _ targetCID: CGSConnectionID,
    _ key: CFString,
    _ value: CFTypeRef
) -> CGError

@main
enum AgentDockApp {
    static func main() {
        AgentDockPaths.ensureExists(AgentDockPaths.root)

        let cid = CGSMainConnectionID()
        _ = CGSSetConnectionProperty(cid, cid, "SetsCursorInBackground" as CFString, kCFBooleanTrue)
        guard SingleInstanceGuard.acquire() else {
            FileHandle.standardError.write(Data("AgentDock is already running.\n".utf8))
            exit(0)
        }

        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

enum SingleInstanceGuard {
    private static var lockDescriptor: Int32 = -1

    static func acquire() -> Bool {
        let path = AgentDockPaths.root.appendingPathComponent("instance.lock").path
        let descriptor = open(path, O_CREAT | O_RDWR, 0o644)
        guard descriptor >= 0 else { return true }
        if flock(descriptor, LOCK_EX | LOCK_NB) != 0 {
            close(descriptor)
            return false
        }
        lockDescriptor = descriptor
        return true
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var store: AgentStore!
    private var windowController: NotchWindowController!
    private var sources: [AgentSource] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        AgentDockPaths.ensureExists(AgentDockPaths.root)
        AgentDockPaths.ensureExists(AgentDockPaths.sourceDir("sessions"))

        store = AgentStore()
        store.start()

        let claude = ClaudeCodeSource()
        store.register(claude)
        sources.append(claude)

        windowController = NotchWindowController(store: store)
        windowController.showOnScreen()

        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.windowController.showOnScreen() }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        sources.forEach { $0.stop() }
    }
}
