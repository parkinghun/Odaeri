//
//  MediaUploadService.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/14/26.
//

import Foundation
import Combine
import Moya
import Alamofire

final class MediaUploadService {
    private let session: Session = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.waitsForConnectivity = true
        return Session(configuration: configuration)
    }()

    private lazy var provider: MoyaProvider<MediaUploadAPI> = {
        var plugins: [PluginType] = []
        #if DEBUG
        plugins.append(NetworkLoggerPlugin(configuration: .init(logOptions: .verbose)))
        #endif
        return MoyaProvider<MediaUploadAPI>(session: session, plugins: plugins)
    }()

    func upload(
        context: UploadContext,
        roomId: String? = nil,
        multiparts: [Moya.MultipartFormData],
        progress: @escaping (Double) -> Void
    ) -> AnyPublisher<[String], NetworkError> {
        let target: MediaUploadAPI
        switch context {
        case .chat:
            guard let roomId = roomId else {
                return Fail(error: NetworkError.invalidRequest("채팅 업로드에는 roomId가 필요합니다."))
                    .eraseToAnyPublisher()
            }
            target = .chatUpload(roomId: roomId, files: multiparts)
        case .community:
            target = .communityUpload(files: multiparts)
        }

        return provider.requestPublisherWithProgress(
            target,
            timeout: 60,
            progress: progress
        )
        .map { (response: MediaFileUploadResponse) in
            response.files
        }
        .eraseToAnyPublisher()
    }
}
