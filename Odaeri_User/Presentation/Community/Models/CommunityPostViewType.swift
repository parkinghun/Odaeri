//
//  CommunityPostViewType.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/16/26.
//

enum CommunityPostViewType {
    case create
    case edit

    var navigationTitle: String {
        switch self {
        case .create:
            return "게시글 작성"
        case .edit:
            return "게시글 수정"
        }
    }
}
