//
//  AdminMenuService.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 2/25/26.
//

import Foundation
import Combine
import Moya

final class AdminMenuService {
    private let provider: MoyaProvider<MenuAPI>

    init(provider: MoyaProvider<MenuAPI> = ProviderFactory.makeMenuProvider()) {
        self.provider = provider
    }

    func updateMenu(menuId: String, request: MenuRequest) -> AnyPublisher<MenuEntity, NetworkError> {
        provider.requestPublisher(.update(menuId: menuId, request: request))
            .map { (response: MenuResponse) in
                AdminMenuDTOMapper.toEntity(response)
            }
            .eraseToAnyPublisher()
    }

    func createMenu(storeId: String, request: MenuRequest) -> AnyPublisher<MenuEntity, NetworkError> {
        provider.requestPublisher(.create(storeId: storeId, request: request))
            .map { (response: MenuResponse) in
                AdminMenuDTOMapper.toEntity(response)
            }
            .eraseToAnyPublisher()
    }
}

private enum AdminMenuDTOMapper {
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
