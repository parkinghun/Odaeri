//
//  GetVideoStreamURLUseCase.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/19/26.
//

import Foundation
import Combine

protocol GetVideoStreamURLUseCase {
    func execute(videoId: String) -> AnyPublisher<VideoStreamEntity, NetworkError>
}

final class DefaultGetVideoStreamURLUseCase: GetVideoStreamURLUseCase {
    private let repository: VideoRepository

    init(repository: VideoRepository) {
        self.repository = repository
    }

    func execute(videoId: String) -> AnyPublisher<VideoStreamEntity, NetworkError> {
        return repository.getVideoStreamingURL(videoId: videoId)
    }
}
