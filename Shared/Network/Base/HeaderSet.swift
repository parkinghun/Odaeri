//
//  HeaderSet.swift
//  Odaeri
//
//  Created by 박성훈 on 12/29/25.
//

import Foundation

struct HeaderSet: OptionSet {
    let rawValue: Int

    // 개별 헤더
    static let contentType = HeaderSet(rawValue: 1 << 0)
    static let accept = HeaderSet(rawValue: 1 << 1)
    static let sesacKey = HeaderSet(rawValue: 1 << 2)
    static let authorization = HeaderSet(rawValue: 1 << 3)
    static let refreshToken = HeaderSet(rawValue: 1 << 4)
    static let multipart = HeaderSet(rawValue: 1 << 5)

    // 자주 사용하는 조합 프리셋
    static let standard: HeaderSet = [.contentType, .accept, .sesacKey]
    static let authenticated: HeaderSet = [.standard, .authorization]
    static let mediaRead: HeaderSet = [.accept, .sesacKey, .authorization]
    static let fileUpload: HeaderSet = [.accept, .authorization, .sesacKey, .multipart]
    static let refresh: HeaderSet = [.accept, .sesacKey, .authorization, .refreshToken]
}

extension HeaderSet {
    func toHeaders() -> [String: String] {
        var headers = [String: String]()

        let headerMappings: [(HeaderSet, () -> (String, String)?)] = [
            (.sesacKey, { ("SeSACKey", APIEnvironment.current.apiKey) }),
            (.accept, { ("Accept", "application/json") }),
            (.contentType, { ("Content-Type", "application/json") }),
            (.multipart, { ("Content-Type", "multipart/form-data") }),
            (.authorization, {
                guard let token = TokenManager.shared.accessToken else { return nil }
                return ("Authorization", token)
            }),
            (.refreshToken, {
                guard let token = TokenManager.shared.refreshToken else { return nil }
                return ("RefreshToken", token)
            })
        ]

        for (option, generator) in headerMappings {
            if self.contains(option), let (key, value) = generator() {
                headers[key] = value
            }
        }

        return headers
    }
}
