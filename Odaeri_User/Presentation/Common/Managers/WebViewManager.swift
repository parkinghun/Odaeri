//
//  WebViewManager.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/4/26.
//

import Foundation

final class WebViewManager {
    static let shared = WebViewManager()

    private init() {}

    func createURLRequest(for path: String) -> URLRequest? {
        let baseURL = APIEnvironment.current.baseURL
        let fullURLString = baseURL.absoluteString + path

        guard let url = URL(string: fullURLString) else {
            return nil
        }

        var request = URLRequest(url: url)
        request.setValue(Bundle.main.value(for: .apiKey), forHTTPHeaderField: "SeSACKey")

        return request
    }
}
