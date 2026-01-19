//
//  VideoRepositoryImpl.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/10/26.
//

import Foundation
import Combine
import Moya

final class VideoRepositoryImpl: VideoRepository {
    private let provider = ProviderFactory.makeVideoProvider()

    func fetchVideoList(next: String?, limit: Int?) -> AnyPublisher<VideoListResult, NetworkError> {
        provider.requestPublisher(.fetchVideoList(next: next, limit: limit))
            .map { (response: VideoListResponse) in
                VideoListResult(
                    videos: response.data.map { VideoEntity(from: $0) },
                    nextCursor: response.nextCursor
                )
            }
            .eraseToAnyPublisher()
    }

    func getVideoStreamingURL(videoId: String) -> AnyPublisher<VideoStreamEntity, NetworkError> {
        provider.requestPublisherWithRetry(.getVideoStreamingURL(videoId: videoId))
            .map { (response: VideoStreamResponse) in
                VideoStreamEntity(from: response)
            }
            .eraseToAnyPublisher()
    }

    func toggleVideoLike(videoId: String, status: Bool) -> AnyPublisher<Void, NetworkError> {
        provider.requestPublisher(.toggleVideoLike(videoId: videoId, status: status))
            .map { (_: EmptyResponse) in () }
            .eraseToAnyPublisher()
    }
}
