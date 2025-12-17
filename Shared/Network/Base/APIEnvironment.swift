//
//  APIEnvironment.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation

enum APIEnvironment {
    case development
    case production

    static var current: APIEnvironment {
        return .development
    }

    var baseURL: URL {
        let urlString = Bundle.main.value(for: .baseURL)
        guard let url = URL(string: urlString) else {
            fatalError("Invalid BaseURL: \(urlString)")
        }
        return url
    }

    var apiKey: String {
        return Bundle.main.value(for: .apiKey)
    }

    var description: String {
        switch self {
        case .development:
            return "Development"
        case .production:
            return "Production"
        }
    }
}
