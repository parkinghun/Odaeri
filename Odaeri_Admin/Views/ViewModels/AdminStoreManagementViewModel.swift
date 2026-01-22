//
//  AdminStoreManagementViewModel.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 2/25/26.
//

import Foundation
import Combine
import UIKit

final class AdminStoreManagementViewModel {
    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
        let selectItem: AnyPublisher<AdminStoreManagementItem, Never>
        let saveStore: AnyPublisher<AdminStoreFormData, Never>
        let saveMenu: AnyPublisher<AdminMenuFormData, Never>
    }

    struct Output {
        let store: AnyPublisher<StoreEntity?, Never>
        let selectedItem: AnyPublisher<AdminStoreManagementItem, Never>
        let isLoading: AnyPublisher<Bool, Never>
        let error: AnyPublisher<String, Never>
    }

    private let storeService: AdminStoreService
    private let menuService: AdminMenuService
    private let mediaUploadService: AdminMediaUploadService
    private let storeSubject = CurrentValueSubject<StoreEntity?, Never>(nil)
    private let selectedItemSubject = CurrentValueSubject<AdminStoreManagementItem, Never>(.storeInfo)
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let errorSubject = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(
        storeService: AdminStoreService = AdminStoreService(),
        menuService: AdminMenuService = AdminMenuService(),
        mediaUploadService: AdminMediaUploadService = AdminMediaUploadService()
    ) {
        self.storeService = storeService
        self.menuService = menuService
        self.mediaUploadService = mediaUploadService
    }

    func transform(input: Input) -> Output {
        input.viewDidLoad
            .sink { [weak self] in
                self?.fetchStore()
            }
            .store(in: &cancellables)

        input.selectItem
            .sink { [weak self] item in
                self?.selectedItemSubject.send(item)
            }
            .store(in: &cancellables)

        input.saveStore
            .sink { [weak self] data in
                self?.updateStore(data: data)
            }
            .store(in: &cancellables)

        input.saveMenu
            .sink { [weak self] data in
                self?.updateMenu(data: data)
            }
            .store(in: &cancellables)

        return Output(
            store: storeSubject.eraseToAnyPublisher(),
            selectedItem: selectedItemSubject.eraseToAnyPublisher(),
            isLoading: isLoadingSubject.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher()
        )
    }

    func reloadStore() {
        fetchStore()
    }
}

private extension AdminStoreManagementViewModel {
    func fetchStore() {
        guard let storeId = AdminStoreSession.shared.storeId else {
            errorSubject.send("가게 ID가 없습니다. 설정에서 등록해주세요.")
            return
        }

        isLoadingSubject.send(true)
        storeService.fetchStoreDetail(storeId: storeId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingSubject.send(false)
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error.errorDescription)
                    }
                },
                receiveValue: { [weak self] store in
                    self?.storeSubject.send(store)
                    if self?.selectedItemSubject.value == .storeInfo {
                        return
                    }
                    self?.selectedItemSubject.send(.storeInfo)
                }
            )
            .store(in: &cancellables)
    }

    func updateStore(data: AdminStoreFormData) {
        guard let store = storeSubject.value else { return }
        let longitude = Double(data.longitude) ?? store.longitude
        let latitude = Double(data.latitude) ?? store.latitude
        let uploadPublisher: AnyPublisher<[String], NetworkError> = data.newImages.isEmpty
            ? Just([]).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
            : mediaUploadService.uploadStoreImages(data.newImages)

        isLoadingSubject.send(true)
        uploadPublisher
            .flatMap { [weak self] uploadedUrls -> AnyPublisher<StoreEntity, NetworkError> in
                guard let self else {
                    return Fail(error: NetworkError.unknown(NSError(domain: "AdminStoreManagement", code: -1)))
                        .eraseToAnyPublisher()
                }
                let imageUrls = data.storeImageUrls + uploadedUrls
                let request = StoreRequest(
                    name: data.name,
                    category: data.category,
                    description: data.description,
                    address: data.address,
                    longitude: longitude,
                    latitude: latitude,
                    open: data.open,
                    close: data.close,
                    parkingGuide: data.parkingGuide,
                    storeImageUrls: imageUrls,
                    hashTags: data.tags,
                    isPicchelin: data.isPicchelin
                )
                return self.storeService.updateStore(storeId: store.storeId, request: request)
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingSubject.send(false)
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error.errorDescription)
                    }
                },
                receiveValue: { [weak self] updatedStore in
                    self?.storeSubject.send(updatedStore)
                }
            )
            .store(in: &cancellables)
    }

    func updateMenu(data: AdminMenuFormData) {
        guard let store = storeSubject.value else { return }
        let isCreate = data.menuId.isEmpty
        let currentMenu = store.menuList.first(where: { $0.menuId == data.menuId })
        let priceValue = Int(data.price) ?? currentMenu?.priceValue ?? 0
        let uploadPublisher: AnyPublisher<String?, NetworkError> = {
            guard let image = data.menuImage else {
                return Just(nil).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
            }
            return mediaUploadService.uploadMenuImage(image)
                .map { Optional($0) }
                .eraseToAnyPublisher()
        }()

        isLoadingSubject.send(true)
        uploadPublisher
            .flatMap { [weak self] uploadedUrl -> AnyPublisher<MenuEntity, NetworkError> in
                guard let self else {
                    return Fail(error: NetworkError.unknown(NSError(domain: "AdminStoreManagement", code: -1)))
                        .eraseToAnyPublisher()
                }
                let menuImageUrl = uploadedUrl ?? currentMenu?.menuImageUrl
                let request = MenuRequest(
                    name: data.name,
                    description: data.description,
                    originInformation: data.originInformation,
                    price: priceValue,
                    category: data.category,
                    tags: data.tags,
                    menuImageUrl: menuImageUrl,
                    isSoldOut: data.isSoldOut
                )
                if isCreate {
                    return self.menuService.createMenu(storeId: store.storeId, request: request)
                }
                guard let menuId = currentMenu?.menuId else {
                    return Fail(error: NetworkError.unknown(NSError(domain: "AdminStoreManagement", code: -2)))
                        .eraseToAnyPublisher()
                }
                return self.menuService.updateMenu(menuId: menuId, request: request)
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingSubject.send(false)
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error.errorDescription)
                    }
                },
                receiveValue: { [weak self] updatedMenu in
                    self?.applyMenuUpdate(updatedMenu, isCreate: isCreate)
                }
            )
            .store(in: &cancellables)
    }

    func applyMenuUpdate(_ updated: MenuEntity, isCreate: Bool = false) {
        guard let store = storeSubject.value else { return }
        let menus: [MenuEntity]
        if isCreate {
            menus = store.menuList + [updated]
        } else {
            menus = store.menuList.map { menu in
                menu.menuId == updated.menuId ? updated : menu
            }
        }
        let updatedStore = StoreEntity(
            storeId: store.storeId,
            name: store.name,
            category: store.category,
            description: store.description,
            address: store.address,
            longitude: store.longitude,
            latitude: store.latitude,
            open: store.open,
            close: store.close,
            estimatedPickupTime: store.estimatedPickupTime,
            parkingGuide: store.parkingGuide,
            storeImageUrls: store.storeImageUrls,
            hashTags: store.hashTags,
            isPicchelin: store.isPicchelin,
            isPick: store.isPick,
            pickCount: store.pickCount,
            totalReviewCount: store.totalReviewCount,
            totalOrderCount: store.totalOrderCount,
            totalRating: store.totalRating,
            creator: store.creator ?? CreatorEntity(userId: "", nick: "", profileImage: nil),
            menuList: menus
        )
        storeSubject.send(updatedStore)
        if isCreate {
            selectedItemSubject.send(.menu(updated))
            return
        }
        if case .menu(let selectedMenu) = selectedItemSubject.value,
           selectedMenu.menuId == updated.menuId {
            selectedItemSubject.send(.menu(updated))
        }
    }

}

enum AdminStoreManagementItem: Hashable {
    case storeInfo
    case addMenu
    case menu(MenuEntity)
}

struct AdminStoreFormData {
    let name: String
    let category: String
    let description: String
    let address: String
    let longitude: String
    let latitude: String
    let open: String
    let close: String
    let parkingGuide: String
    let tags: [String]
    let storeImageUrls: [String]
    let newImages: [UIImage]
    let isPicchelin: Bool
}

struct AdminMenuFormData {
    let menuId: String
    let name: String
    let description: String
    let originInformation: String
    let price: String
    let category: String
    let tags: [String]
    let isSoldOut: Bool
    let menuImage: UIImage?
}
