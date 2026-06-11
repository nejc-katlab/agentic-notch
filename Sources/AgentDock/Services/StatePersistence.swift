import Foundation

struct AppState: Codable {
    var launchAtLogin: Bool = false
    var autoExpandOnAttention: Bool = true
    var sleepPrevention: SleepPreventionMode = .never
    var permissionInterception: Bool = false
}

final class StatePersistence {
    static let shared = StatePersistence()

    private let queue = DispatchQueue(label: "agentdock.state")
    private let url = AgentDockPaths.stateFile

    func load() -> AppState {
        queue.sync {
            guard let data = try? Data(contentsOf: url),
                  let state = try? JSONDecoder().decode(AppState.self, from: data) else {
                return AppState()
            }
            return state
        }
    }

    func update(_ mutate: (inout AppState) -> Void) {
        queue.sync {
            var state = (try? JSONDecoder().decode(AppState.self, from: Data(contentsOf: url))) ?? AppState()
            mutate(&state)
            AgentDockPaths.ensureExists(AgentDockPaths.root)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            if let data = try? encoder.encode(state) {
                try? data.write(to: url, options: .atomic)
            }
        }
    }
}
