//
//  AdminStoreService.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 1/18/26.
//

import Foundation
import Combine
import Moya
import UIKit

final class AdminStoreService {
    private enum Constant {
        static let maxImageDimension: CGFloat = 1080
        static let compressionQuality: CGFloat = 0.8
    }

    private let userProvider: MoyaProvider<StoreAPI.User>
    private let adminProvider: MoyaProvider<StoreAPI.Admin>

    init(
        userProvider: MoyaProvider<StoreAPI.User> = ProviderFactory.makeStoreProvider(),
        adminProvider: MoyaProvider<StoreAPI.Admin> = ProviderFactory.makeStoreAdminProvider()
    ) {
        self.userProvider = userProvider
        self.adminProvider = adminProvider
    }

    func fetchStoreDetail(storeId: String) -> AnyPublisher<StoreEntity, NetworkError> {
        userProvider.requestPublisher(.fetchStoreDetail(storeId: storeId))
            .map { (response: StoreResponse) in
                AdminStoreDTOMapper.toEntity(response)
            }
            .eraseToAnyPublisher()
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
                name: "files",
                fileName: "store_\(UUID().uuidString).jpg",
                mimeType: "image/jpeg"
            )
        }

        guard multiparts.count == images.count else {
            return Fail(error: NetworkError.unknown(NSError(
                domain: "AdminStoreService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "이미지 처리에 실패했습니다."]
            ))).eraseToAnyPublisher()
        }

        return adminProvider.requestPublisher(.uploadImages(files: multiparts))
            .map { (response: StoreImageUploadResponse) in
                response.imageUrls
            }
            .eraseToAnyPublisher()
    }

    func createStore(request: StoreRequest) -> AnyPublisher<StoreEntity, NetworkError> {
        adminProvider.requestPublisher(.create(request: request))
            .map { (response: StoreResponse) in
                AdminStoreDTOMapper.toEntity(response)
            }
            .eraseToAnyPublisher()
    }

    func updateStore(storeId: String, request: StoreRequest) -> AnyPublisher<StoreEntity, NetworkError> {
        adminProvider.requestPublisher(.update(storeId: storeId, request: request))
            .map { (response: StoreResponse) in
                AdminStoreDTOMapper.toEntity(response)
            }
            .eraseToAnyPublisher()
    }
}

private enum AdminStoreDTOMapper {
    static func toEntity(_ response: StoreResponse) -> StoreEntity {
        StoreEntity(
            storeId: response.storeId,
            name: response.name,
            category: response.category,
            description: response.description,
            address: response.address,
            longitude: response.geolocation.longitude,
            latitude: response.geolocation.latitude,
            open: response.open,
            close: response.close,
            estimatedPickupTime: response.estimatedPickupTime,
            parkingGuide: response.parkingGuide,
            storeImageUrls: response.storeImageUrls,
            hashTags: response.hashTags,
            isPicchelin: response.isPicchelin,
            isPick: response.isPick,
            pickCount: response.pickCount,
            totalReviewCount: response.totalReviewCount,
            totalOrderCount: response.totalOrderCount,
            totalRating: response.totalRating,
            creator: CreatorEntity(
                userId: response.creator.userId,
                nick: response.creator.nick,
                profileImage: response.creator.profileImage
            ),
            menuList: response.menuList.map(toEntity)
        )
    }

    static func toEntity(_ response: MenuResponse) -> MenuEntity {
        MenuEntity(
            menuId: response.menuId,
            name: response.name,
            description: response.description,
            originInformation: response.originInformation,
            price: response.price,
            category: response.category,
            tags: response.tags,
            menuImageUrl: response.menuImageUrl,
            isSoldOut: response.isSoldOut
        )
    }
}
