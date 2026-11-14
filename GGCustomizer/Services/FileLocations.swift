import Foundation

enum GGFileLocations {
    static let applicationFolderName = "GGCustomizer"

    static func applicationSupportDirectory(fileManager: FileManager = .default) -> URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let directory = base.appendingPathComponent(applicationFolderName, isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func cachesDirectory(fileManager: FileManager = .default) -> URL {
        let base = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let directory = base.appendingPathComponent(applicationFolderName, isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func artworkDirectory(fileManager: FileManager = .default) -> URL {
        let directory = applicationSupportDirectory(fileManager: fileManager)
            .appendingPathComponent("Artwork", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func exportsDirectory(fileManager: FileManager = .default) -> URL {
        let directory = cachesDirectory(fileManager: fileManager)
            .appendingPathComponent("Exports", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func recoveryDirectory(fileManager: FileManager = .default) -> URL {
        let directory = applicationSupportDirectory(fileManager: fileManager)
            .appendingPathComponent("Recovery", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func removeTemporaryExports(fileManager: FileManager = .default) -> Int {
        let directory = exportsDirectory(fileManager: fileManager)
        let files = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        var removed = 0
        for file in files where (try? fileManager.removeItem(at: file)) != nil {
            removed += 1
        }
        return removed
    }
}
