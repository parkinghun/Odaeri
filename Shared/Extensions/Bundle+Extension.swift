//
//  Bundle+Extension.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation

extension Bundle {
    enum InfoPlistKey: String {
        case baseURL = "BaseURL"
        case apiKey = "APIKey"
        case iamportUserCode = "IamPortUserCode"
        case kakaoNativeAppKey = "KAKAO_NATIVE_APP_KEY"
    }

    func value(for key: InfoPlistKey) -> String {
        guard let value = object(forInfoDictionaryKey: key.rawValue) as? String else {
            fatalError("\(key.rawValue) not found in Info.plist.")
        }
        print(key.rawValue, " - \(value)" )
        return value
    }
}
