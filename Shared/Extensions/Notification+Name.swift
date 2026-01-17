//
//  Notification+Name.swift
//  Odaeri
//
//  Created by 박성훈 on 1/5/26.
//

import Foundation

extension Notification.Name {
    static let unauthorizedAccess = Notification.Name("com.odaeri.unauthorizedAccess")
    static let refreshTokenExpired = Notification.Name("com.odaeri.refreshTokenExpired")
    static let pendingPaymentValidated = Notification.Name("com.odaeri.pendingPaymentValidated")
    static let storeLikeUpdated = Notification.Name("com.odaeri.storeLikeUpdated")
    static let communityPostDidUpdate = Notification.Name("com.odaeri.communityPostDidUpdate")
    static let communityPostInteractionDidUpdate = Notification.Name("com.odaeri.communityPostInteractionDidUpdate")
}

struct PendingPaymentValidatedInfo {
    let validationEntity: PaymentValidationEntity
    let storeName: String
    let count: Int
}

struct StoreLikeUpdateInfo {
    let storeId: String
    let isPick: Bool
    let pickCount: Int
}

struct CommunityPostInteractionUpdateInfo {
    let postId: String
    let isLiked: Bool
    let likeCount: Int
    let commentCount: Int
}
