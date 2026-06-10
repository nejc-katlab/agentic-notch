import Foundation

struct SleepPreventionMode: OptionSet, Codable, Hashable {
    let rawValue: Int

    static let active = SleepPreventionMode(rawValue: 1 << 0)
    static let needsAttention = SleepPreventionMode(rawValue: 1 << 1)

    static let never: SleepPreventionMode = []
}
