// created by musesum on 6/10/25

import Foundation

/// Codable struct for sharing archive data between peers
public struct ArchiveFrame: Codable, Sendable {
    public let url: URL
    public let data: Data
    public let name: String
    
    public init(url: URL, data: Data) {
        self.url = url
        self.data = data
        self.name = url.deletingPathExtension().lastPathComponent
    }
}
