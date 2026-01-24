//
//  VideoRepository.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/10/26.
//

import Foundation
import Combine

protocol VideoRepository {
    func fetchVideoList(next: String?, limit: Int?) -> AnyPublisher<VideoListResult, NetworkError>
    func getVideoStreamingURL(videoId: String) -> AnyPublisher<VideoStreamEntity, NetworkError>
    func toggleVideoLike(videoId: String, status: Bool) -> AnyPublisher<Void, NetworkError>
    func getSubtitleFile(path: String) -> AnyPublisher<String, NetworkError>
}
