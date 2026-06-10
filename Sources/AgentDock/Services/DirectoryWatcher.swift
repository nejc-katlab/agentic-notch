import Foundation

final class DirectoryWatcher<T: Decodable> {
    var onChange: (([(url: URL, value: T)]) -> Void)?

    private let directory: URL
    private let queue: DispatchQueue
    private let pollInterval: DispatchTimeInterval
    private var dirSource: DispatchSourceFileSystemObject?
    private var dirFD: Int32 = -1
    private var pollTimer: DispatchSourceTimer?

    init(directory: URL, label: String, pollInterval: DispatchTimeInterval = .milliseconds(500)) {
        self.directory = directory
        self.queue = DispatchQueue(label: label)
        self.pollInterval = pollInterval
        AgentDockPaths.ensureExists(directory)
    }

    func start() {
        scan()
        watchDirectory()
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + pollInterval, repeating: pollInterval)
        timer.setEventHandler { [weak self] in self?.scan() }
        timer.resume()
        pollTimer = timer
    }

    func stop() {
        pollTimer?.cancel(); pollTimer = nil
        dirSource?.cancel(); dirSource = nil
        dirFD = -1
    }

    private func watchDirectory() {
        let fd = open(directory.path, O_EVTONLY)
        guard fd >= 0 else { return }
        dirFD = fd
        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd, eventMask: [.write, .delete, .rename, .extend], queue: queue
        )
        src.setEventHandler { [weak self] in self?.scan() }
        src.setCancelHandler { [fd] in close(fd) }
        src.resume()
        dirSource = src
    }

    private func scan() {
        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            onChange?([])
            return
        }

        var values: [(url: URL, value: T)] = []
        let decoder = JSONDecoder()
        for url in entries where url.pathExtension == "json" {
            guard let data = try? Data(contentsOf: url),
                  let value = try? decoder.decode(T.self, from: data) else { continue }
            values.append((url, value))
        }
        onChange?(values)
    }
}
