//
//  PushDTO.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/18/26.
//

import Foundation

struct PushRequest: Encodable {
    let userId: String
    let title: String
    let subtitle: String
    let body: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case title, subtitle, body
    }
}
