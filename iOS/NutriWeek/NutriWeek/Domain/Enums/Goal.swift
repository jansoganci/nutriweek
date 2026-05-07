import Foundation

enum Goal: String, Codable, CaseIterable, Sendable {
    case cut
    case bulk
    case maintain
}
