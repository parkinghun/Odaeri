//
//  ProviderFactory.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation
import Moya

enum ProviderFactory {
    static func makeAuthProvider() -> MoyaProvider<AuthAPI> {
        return MoyaProvider<AuthAPI>(plugins: makePlugins())
    }

    static func makeUserProvider() -> MoyaProvider<UserAPI> {
        return MoyaProvider<UserAPI>(plugins: makePlugins())
    }

    static func makeStoreProvider() -> MoyaProvider<StoreAPI.User> {
        return MoyaProvider<StoreAPI.User>(plugins: makePlugins())
    }

    static func makeOrderProvider() -> MoyaProvider<OrderAPI> {
        return MoyaProvider<OrderAPI>(plugins: makePlugins())
    }

    static func makePaymentProvider() -> MoyaProvider<PaymentAPI> {
        return MoyaProvider<PaymentAPI>(plugins: makePlugins())
    }

    static func makeReviewProvider() -> MoyaProvider<StoreReviewAPI> {
        return MoyaProvider<StoreReviewAPI>(plugins: makePlugins())
    }

    static func makeCommunityPostProvider() -> MoyaProvider<CommunityPostAPI> {
        return MoyaProvider<CommunityPostAPI>(plugins: makePlugins())
    }

    static func makeCommunityCommentProvider() -> MoyaProvider<CommunityCommentAPI> {
        return MoyaProvider<CommunityCommentAPI>(plugins: makePlugins())
    }

    static func makeChatProvider() -> MoyaProvider<ChatAPI> {
        return MoyaProvider<ChatAPI>(plugins: makePlugins())
    }

    static func makeBannerProvider() -> MoyaProvider<BannerAPI> {
        return MoyaProvider<BannerAPI>(plugins: makePlugins())
    }

    static func makePushProvider() -> MoyaProvider<PushAPI> {
        return MoyaProvider<PushAPI>(plugins: makePlugins())
    }

    static func makeVideoProvider() -> MoyaProvider<VideoAPI> {
        return MoyaProvider<VideoAPI>(plugins: makePlugins())
    }

    static func makeStoreAdminProvider() -> MoyaProvider<StoreAPI.Admin> {
        return MoyaProvider<StoreAPI.Admin>(plugins: makePlugins())
    }

    static func makeMenuProvider() -> MoyaProvider<MenuAPI> {
        return MoyaProvider<MenuAPI>(plugins: makePlugins())
    }

    private static func makePlugins() -> [PluginType] {
        var plugins: [PluginType] = []

        #if DEBUG
        plugins.append(NetworkLoggerPlugin(configuration: .init(logOptions: .verbose)))
        #endif

        return plugins
    }
}
