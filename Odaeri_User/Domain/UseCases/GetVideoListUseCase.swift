//
//  GetVideoListUseCase.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/19/26.
//

import Foundation
import Combine

protocol GetVideoListUseCase {
    func execute(next: String?, limit: Int?) -> AnyPublisher<VideoListResult, NetworkError>
}

final class DefaultGetVideoListUseCase: GetVideoListUseCase {
    private let repository: VideoRepository

    init(repository: VideoRepository) {
        self.repository = repository
    }

    func execute(next: String?, limit: Int?) -> AnyPublisher<VideoListResult, NetworkError> {
        return repository.fetchVideoList(next: next, limit: limit)
    }
}
