//
//  Category.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/24/25.
//

import UIKit

enum Category: CaseIterable {
    case coffee
    case fastFood
    case dessert
    case bakery
    case more

    var image: UIImage? {
        switch self {
        case .coffee: return AppImage.coffee
        case .fastFood: return AppImage.fastFood
        case .dessert: return AppImage.dessert
        case .bakery: return AppImage.bakery
        case .more: return AppImage.more
        }
    }

    var title: String {
        switch self {
        case .coffee: return "커피"
        case .fastFood: return "패스트푸드"
        case .dessert: return "디저트"
        case .bakery: return "베이커리"
        case .more: return "more"
        }
    }
}
