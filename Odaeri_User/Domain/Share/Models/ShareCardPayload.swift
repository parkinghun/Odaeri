//
//  ShareCardPayload.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/24/26.
//

import Foundation

struct ShareCardPayload: Codable, Hashable {
    let title: String
    let thumbnailUrl: String
    let videoId: String
}

enum ShareCardMessageFormatter {
    static let prefix = "공유"

    static func makeContent(payload: ShareCardPayload) -> String {
        guard let data = try? JSONEncoder().encode(payload) else {
            return prefix
        }
        let encoded = data.base64EncodedString()
        return "\(prefix)|\(encoded)"
    }

    static func parse(content: String) -> ShareCardPayload? {
        let parts = content.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2 else { return nil }
        guard String(parts[0]) == prefix else { return nil }
        guard let data = Data(base64Encoded: String(parts[1])) else { return nil }
        return try? JSONDecoder().decode(ShareCardPayload.self, from: data)
    }
}
