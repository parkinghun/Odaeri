//
//  AdminMediaUploadService.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 2/25/26.
//

import Foundation
import Combine
import Moya
import UIKit

final class AdminMediaUploadService {
    private enum Constant {
        static let maxImageDimension: CGFloat = 1080
        static let compressionQuality: CGFloat = 0.8
        static let storeFileKey = "files"
        static let menuFileKey = "menu_image"
    }

    private let provider: MoyaProvider<MediaUploadAPI>

    init(provider: MoyaProvider<MediaUploadAPI> = ProviderFactory.makeMediaUploadProvider()) {
        self.provider = provider
    }

    func uploadStoreImages(_ images: [UIImage]) -> AnyPublisher<[String], NetworkError> {
        let multiparts = images.compactMap { image -> MultipartFormData? in
            guard let data = image.processForUpload(
                maxDimension: Constant.maxImageDimension,
                compressionQuality: Constant.compressionQuality
            ) else {
                return nil
            }
            return MultipartFormData(
                provider: .data(data),
                name: Constant.storeFileKey,
                fileName: "store_\(UUID().uuidString).jpg",
                mimeType: "image/jpeg"
            )
        }

        guard multiparts.count == images.count else {
            return Fail(error: NetworkError.unknown(NSError(
                domain: "AdminMediaUploadService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "이미지 처리에 실패했습니다."]
            ))).eraseToAnyPublisher()
        }

        return provider.requestPublisher(.storeUpload(files: multiparts))
            .map { (response: StoreImageUploadResponse) in
                response.imageUrls
            }
            .eraseToAnyPublisher()
    }

    func uploadMenuImage(_ image: UIImage) -> AnyPublisher<String, NetworkError> {
        guard let data = image.processForUpload(
            maxDimension: Constant.maxImageDimension,
            compressionQuality: Constant.compressionQuality
        ) else {
            return Fail(error: NetworkError.unknown(NSError(
                domain: "AdminMediaUploadService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "이미지 처리에 실패했습니다."]
            ))).eraseToAnyPublisher()
        }

        let multipart = MultipartFormData(
            provider: .data(data),
            name: Constant.menuFileKey,
            fileName: "menu_\(UUID().uuidString).jpg",
            mimeType: "image/jpeg"
        )

        return provider.requestPublisher(.menuUpload(files: [multipart]))
            .map { (response: MenuImageUploadResponse) in
                response.imageUrl
            }
            .eraseToAnyPublisher()
    }
}
