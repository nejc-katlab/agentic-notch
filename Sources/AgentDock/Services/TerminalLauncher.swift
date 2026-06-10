import AppKit

enum TerminalLauncher {
    private struct TerminalApp {
        let displayName: String
        let bundleId: String
        let focusByTTY: ((String) -> Bool)?
    }

    private static let known: [TerminalApp] = [
        .init(displayName: "Warp",      bundleId: "dev.warp.Warp-Stable", focusByTTY: nil),
        .init(displayName: "Ghostty",   bundleId: "com.mitchellh.ghostty", focusByTTY: nil),
        .init(displayName: "iTerm",     bundleId: "com.googlecode.iterm2", focusByTTY: focusITermByTTY),
        .init(displayName: "WezTerm",   bundleId: "com.github.wez.wezterm", focusByTTY: nil),
        .init(displayName: "Alacritty", bundleId: "io.alacritty", focusByTTY: nil),
        .init(displayName: "kitty",     bundleId: "net.kovidgoyal.kitty", focusByTTY: nil),
        .init(displayName: "Hyper",     bundleId: "co.zeit.hyper", focusByTTY: nil),
        .init(displayName: "Terminal",  bundleId: "com.apple.Terminal", focusByTTY: focusAppleTerminalByTTY),
    ]

    static func reveal(session: AgentSession) {
        let path = expand(session.cwd) ?? FileManager.default.homeDirectoryForCurrentUser.path

        if let raw = session.warpFocusUrl, let url = URL(string: raw) {
            NSWorkspace.shared.open(url)
            activate(bundleId: "dev.warp.Warp-Stable")
            return
        }

        if let sid = session.termSessionId, session.termProgram?.lowercased().contains("iterm") == true {
            if focusITermBySessionId(sid) {
                activate(bundleId: "com.googlecode.iterm2")
                return
            }
        }

        if let tty = session.tty {
            for terminal in known where terminal.focusByTTY != nil && isInstalled(terminal.bundleId) {
                if terminal.focusByTTY?(tty) == true {
                    activate(bundleId: terminal.bundleId)
                    return
                }
            }
        }

        if let terminal = pickTerminal() {
            openIn(terminal: terminal, path: path)
        } else {
            openWithFallback(path: path)
        }
    }

    private static func focusITermBySessionId(_ sid: String) -> Bool {
        let script = """
        tell application "iTerm"
          repeat with w in windows
            repeat with t in tabs of w
              repeat with s in sessions of t
                if (unique id of s) is "\(sid)" then
                  tell s to select
                  activate
                  return "ok"
                end if
              end repeat
            end repeat
          end repeat
        end tell
        return "nope"
        """
        let result = runAppleScript(script)
        return result.success && result.output == "ok"
    }

    private static func pickTerminal() -> TerminalApp? {
        if let frontId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
           let match = known.first(where: { $0.bundleId == frontId }) {
            return match
        }
        let running = Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
        if let firstRunning = known.first(where: { running.contains($0.bundleId) }) {
            return firstRunning
        }
        return known.first(where: { isInstalled($0.bundleId) })
    }

    private static func isInstalled(_ bundleId: String) -> Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) != nil
    }

    private static func activate(bundleId: String) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else { return }
        let cfg = NSWorkspace.OpenConfiguration()
        cfg.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: cfg, completionHandler: nil)
    }

    private static func openIn(terminal: TerminalApp, path: String) {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: terminal.bundleId) else {
            openWithFallback(path: path); return
        }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        config.createsNewApplicationInstance = false
        let dirURL = URL(fileURLWithPath: path, isDirectory: true)
        NSWorkspace.shared.open([dirURL], withApplicationAt: appURL, configuration: config) { _, error in
            if let error {
                NSLog("AgentDock: failed to open \(terminal.displayName) at \(path): \(error)")
                openWithFallback(path: path)
            }
        }
    }

    private static func openWithFallback(path: String) {
        NSWorkspace.shared.open(URL(fileURLWithPath: path, isDirectory: true))
    }

    private static func expand(_ path: String?) -> String? {
        guard let path else { return nil }
        return (path as NSString).expandingTildeInPath
    }

    @discardableResult
    private static func runAppleScript(_ source: String) -> (success: Bool, output: String?) {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return (false, nil) }
        let result = script.executeAndReturnError(&error)
        if let error {
            NSLog("AgentDock AppleScript error: \(error)")
            return (false, nil)
        }
        return (true, result.stringValue)
    }

    private static func focusAppleTerminalByTTY(_ tty: String) -> Bool {
        let script = """
        tell application "Terminal"
          repeat with w in windows
            repeat with t in tabs of w
              if (tty of t) is "\(tty)" then
                set selected of t to true
                set index of w to 1
                activate
                return "ok"
              end if
            end repeat
          end repeat
        end tell
        return "nope"
        """
        let result = runAppleScript(script)
        return result.success && result.output == "ok"
    }

    private static func focusITermByTTY(_ tty: String) -> Bool {
        let script = """
        tell application "iTerm"
          repeat with w in windows
            repeat with t in tabs of w
              repeat with s in sessions of t
                if (tty of s) is "\(tty)" then
                  tell s to select
                  activate
                  return "ok"
                end if
              end repeat
            end repeat
          end repeat
        end tell
        return "nope"
        """
        let result = runAppleScript(script)
        return result.success && result.output == "ok"
    }

}
