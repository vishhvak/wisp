import Foundation
import os

// Wisp's logging: every significant runtime event goes BOTH to the unified system log (viewable
// live with `log stream --predicate 'subsystem == "com.wisp.app"' --level debug`) and to a plain
// file at ~/Library/Logs/Wisp.log (easy to tail / attach to a bug report). The file is what makes
// "nothing works lol" debuggable after the fact — the unified log alone is easy to lose.
enum WispLog {
    static let subsystem = "com.wisp.app"

    static let logFileURL: URL = {
        let logsDirectory = FileManager.default
            .urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Logs", isDirectory: true)
        try? FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
        return logsDirectory.appendingPathComponent("Wisp.log")
    }()

    private static let osLoggersByCategory = OSAllocatedUnfairLock(initialState: [String: Logger]())

    private static let fileWriteQueue = DispatchQueue(label: "com.wisp.app.log-file", qos: .utility)

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()

    // Log one event. Categories group related events (state, hotkeys, voice, overlay, notch, chat).
    static func log(_ category: String, _ message: String) {
        let osLogger = osLoggersByCategory.withLock { loggers in
            if let existingLogger = loggers[category] { return existingLogger }
            let newLogger = Logger(subsystem: subsystem, category: category)
            loggers[category] = newLogger
            return newLogger
        }
        osLogger.info("\(message, privacy: .public)")

        let timestampedLine = "\(timestampFormatter.string(from: Date())) [\(category)] \(message)\n"
        fileWriteQueue.async {
            guard let lineData = timestampedLine.data(using: .utf8) else { return }
            if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                defer { try? fileHandle.close() }
                _ = try? fileHandle.seekToEnd()
                try? fileHandle.write(contentsOf: lineData)
            } else {
                try? lineData.write(to: logFileURL)
            }
        }
    }
}
