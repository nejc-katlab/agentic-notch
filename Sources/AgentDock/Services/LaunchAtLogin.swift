import ServiceManagement

enum LaunchAtLogin {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    @discardableResult
    static func set(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            StatePersistence.shared.update { $0.launchAtLogin = enabled }
            return true
        } catch {
            NSLog("AgentDock: LaunchAtLogin toggle failed: \(error)")
            return false
        }
    }
}
