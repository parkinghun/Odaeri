//
//  ChatFileType.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/28/26.
//

import Foundation

enum ChatFileType: Hashable {
    case pdf
    case zip
    case other

    static func from(fileExtension: String) -> ChatFileType {
        switch fileExtension.lowercased() {
        case "pdf":
            return .pdf
        case "zip":
            return .zip
        default:
            return .other
        }
    }
}
