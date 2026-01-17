//
//  StoreSearchViewType.swift
//  Odaeri
//
//  Created by 박성훈 on 01/16/26.
//

import Foundation

enum StoreSearchViewType {
    case home
    case community

    var navigationTitle: String {
        switch self {
        case .home:
            return "가게 검색"
        case .community:
            return "가게 선택"
        }
    }

    var searchPlaceholder: String {
        "가게 이름을 검색해보세요"
    }

    var emptyStateMessage: String {
        switch self {
        case .home:
            return "원하시는 가게를 검색해보세요."
        case .community:
            return "방문한 가게가 없어요.\n가게를 직접 검색해서 입력해주세요."
        }
    }

    var showsRecentStores: Bool {
        switch self {
        case .home:
            return false
        case .community:
            return true
        }
    }
}
