//
//  ToggleVideoLikeUseCase.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/25/26.
//

import Foundation
import Combine

protocol ToggleVideoLikeUseCase {
    func execute(videoId: String, status: Bool) -> AnyPublisher<Void, NetworkError>
}

final class DefaultToggleVideoLikeUseCase: ToggleVideoLikeUseCase {
    private let repository: VideoRepository

    init(repository: VideoRepository) {
        self.repository = repository
    }

    func execute(videoId: String, status: Bool) -> AnyPublisher<Void, NetworkError> {
        return repository.toggleVideoLike(videoId: videoId, status: status)
    }
}
