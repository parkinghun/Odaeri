//
//  BaseResponse.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation

struct BaseResponse<T: Decodable>: Decodable {
    let success: Bool
    let message: String?
    let data: T?

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case data
    }
}

struct EmptyData: Decodable {}
