//
//  TabBarItem.swift
//  Odaeri
//
//  Created by 박성훈 on 12/18/25.
//

import UIKit

enum TabBarItem: Int, CaseIterable {
    case home = 0
    case order = 1
    case pick = 2
    case community = 3
    case profile = 4

    var title: String {
        switch self {
        case .home: return "홈"
        case .order: return "주문"
        case .pick: return "픽"
        case .community: return "커뮤니티"
        case .profile: return "프로필"
        }
    }

    var emptyImage: UIImage? {
        switch self {
        case .home: return AppImage.homeEmpty
        case .order: return AppImage.orderEmpty
        case .pick: return AppImage.pickEmpty
        case .community: return AppImage.communityEmpty
        case .profile: return AppImage.profileEmpty
        }
    }

    var fillImage: UIImage? {
        switch self {
        case .home: return AppImage.homeFill
        case .order: return AppImage.orderFill
        case .pick: return AppImage.pickFill
        case .community: return AppImage.communityFill
        case .profile: return AppImage.profileFill
        }
    }

    var isSpecial: Bool {
        return self == .pick
    }
}
