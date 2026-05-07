import Foundation

protocol CacheStore: Sendable {
    func load<T: Decodable>(_ type: T.Type, key: String) throws -> T?
    func save<T: Encodable>(_ value: T, key: String) throws
    func remove(key: String) throws
}

struct FileCacheStore: CacheStore {
    private let directoryURL: URL
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(
        namespace: String = "NutriWeekCache",
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        let baseDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.directoryURL = baseDirectory.appendingPathComponent(namespace, isDirectory: true)
        self.decoder = decoder
        self.encoder = encoder
    }

    func load<T: Decodable>(_ type: T.Type, key: String) throws -> T? {
        let url = fileURL(for: key)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try decoder.decode(type, from: data)
    }

    func save<T: Encodable>(_ value: T, key: String) throws {
        try ensureDirectory()
        let data = try encoder.encode(value)
        try data.write(to: fileURL(for: key), options: .atomic)
    }

    func remove(key: String) throws {
        let url = fileURL(for: key)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }

    private func fileURL(for key: String) -> URL {
        let safeKey = key.replacingOccurrences(of: "/", with: "_")
        return directoryURL.appendingPathComponent("\(safeKey).json")
    }

    private func ensureDirectory() throws {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }
}
