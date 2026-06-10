import Foundation

enum StatsRange: String, CaseIterable {
    case today = "Today"
    case week = "7 days"
    case all = "All"

    var cutoff: TimeInterval {
        switch self {
        case .today: return Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        case .week: return Date().timeIntervalSince1970 - 7 * 86_400
        case .all: return 0
        }
    }
}

struct ProjectStats: Identifiable {
    let project: String
    var workingSeconds: Double = 0
    var attentionSeconds: Double = 0
    var attentionWaits: Int = 0
    var sessionIds: Set<String> = []

    var id: String { project }
    var sessions: Int { sessionIds.count }

    var workingLabel: String { Self.duration(workingSeconds) }

    static func duration(_ seconds: Double) -> String {
        let s = Int(seconds)
        if s < 60 { return "\(s)s" }
        if s < 3600 { return "\(s / 60)m" }
        return String(format: "%dh %02dm", s / 3600, (s % 3600) / 60)
    }
}

enum StatsAggregator {
    static func aggregate(range: StatsRange) -> [ProjectStats] {
        let cutoff = range.cutoff
        var byProject: [String: ProjectStats] = [:]

        for line in historyLines() {
            guard let data = line.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  obj["type"] as? String == "interval",
                  let kind = obj["kind"] as? String,
                  let start = obj["start"] as? Double,
                  let end = obj["end"] as? Double,
                  end > cutoff else { continue }
            let project = (obj["project"] as? String) ?? "—"
            let sessionId = (obj["sessionId"] as? String) ?? ""
            let clipped = end - max(start, cutoff)
            var stats = byProject[project] ?? ProjectStats(project: project)
            if kind == "working" {
                stats.workingSeconds += clipped
            } else {
                stats.attentionSeconds += clipped
                stats.attentionWaits += 1
            }
            if !sessionId.isEmpty { stats.sessionIds.insert(sessionId) }
            byProject[project] = stats
        }

        return byProject.values.sorted { $0.workingSeconds > $1.workingSeconds }
    }

    private static func historyLines() -> [String] {
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(at: AgentDockPaths.root, includingPropertiesForKeys: nil) else {
            return []
        }
        let files = entries
            .filter { $0.lastPathComponent.hasPrefix("history") && $0.pathExtension == "jsonl" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        return files.flatMap { url -> [String] in
            guard let content = try? String(contentsOf: url, encoding: .utf8) else { return [] }
            return content.split(separator: "\n").map(String.init)
        }
    }
}
