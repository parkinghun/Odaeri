//
//  PushNotificationService.swift
//  Odaeri
//
//  Created by 박성훈 on 1/18/26.
//

import Foundation
import Combine
import Moya

final class PushNotificationService {
    private let provider: MoyaProvider<PushAPI>

    init(provider: MoyaProvider<PushAPI> = ProviderFactory.makePushProvider()) {
        self.provider = provider
    }

    func sendTestPush(request: PushRequest) -> AnyPublisher<Void, NetworkError> {
        return provider.requestPublisher(.pushNotification(request: request))
    }
}
