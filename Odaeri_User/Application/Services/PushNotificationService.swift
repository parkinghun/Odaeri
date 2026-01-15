//
//  PushNotificationService.swift
//  Odaeri
//
//  Created by 박성훈 on 1/13/26.
//

import Foundation
import Combine
import Moya

final class PushNotificationService {
    private let provider: MoyaProvider<PushAPI>

    init(provider: MoyaProvider<PushAPI> = ProviderFactory.makePushProvider()) {
        self.provider = provider
    }

    func registerTokenIfNeeded(token: String) -> AnyPublisher<Bool, Never> {
        guard !token.isEmpty else {
            return Just(false).eraseToAnyPublisher()
        }

        let deviceId = DeviceIdManager.shared.deviceId
        let publisher: AnyPublisher<Void, NetworkError> = provider.requestPublisher(
            .registerPushToken(token: token, deviceId: deviceId)
        )
        return publisher
            .map { _ in true }
            .catch { _ in Just(false) }
            .eraseToAnyPublisher()
    }

    func unregisterTokenIfNeeded(token: String) -> AnyPublisher<Bool, Never> {
        guard !token.isEmpty else {
            return Just(false).eraseToAnyPublisher()
        }

        let deviceId = DeviceIdManager.shared.deviceId
        let publisher: AnyPublisher<Void, NetworkError> = provider.requestPublisher(
            .unregisterPushToken(deviceId: deviceId)
        )
        return publisher
            .map { _ in true }
            .catch { _ in Just(false) }
            .eraseToAnyPublisher()
    }
}
