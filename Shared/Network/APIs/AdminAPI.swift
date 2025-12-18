//
//  AdminAPI.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation
import Moya

enum AdminAPI {
    case uploadStoreImages(files: [Data])
    case createStore(request: StoreRequest)
    case updateStore(storeId: String, request: StoreRequest)
    case uploadMenuImage(imageData: Data)
    case createMenu(storeId: String, request: MenuRequest)
    case updateMenu(menuId: String, request: MenuRequest)
}

extension AdminAPI: BaseAPI {
    var endpoint: String {
        switch self {
        case .uploadStoreImages:
            return "/stores/files"
        case .createStore:
            return "/stores"
        case .updateStore(let storeId, _):
            return "/stores/\(storeId)"
        case .uploadMenuImage:
            return "/menus/image"
        case .createMenu(let storeId, _):
            return "/menus/stores/\(storeId)"
        case .updateMenu(let menuId, _):
            return "/menus/\(menuId)"
        }
    }

    var method: Moya.Method {
        switch self {
        case .uploadStoreImages, .createStore, .uploadMenuImage, .createMenu:
            return .post
        case .updateStore, .updateMenu:
            return .put


        }
    }

    var task: Task {
        switch self {
        case .uploadStoreImages(let files):
            var formData = [MultipartFormData]()
            for (index, fileData) in files.enumerated() {
                formData.append(
                    MultipartFormData(
                        provider: .data(fileData),
                        name: "files",
                        fileName: "store_image_\(index).jpg",
                        mimeType: "image/jpeg"
                    )
                )
            }
            return .uploadMultipart(formData)

        case .createStore(let request):
            return .requestJSONEncodable(request)

        case .updateStore(_, let request):
            return .requestJSONEncodable(request)

        case .uploadMenuImage(let imageData):
            let formData = MultipartFormData(
                provider: .data(imageData),
                name: "menu_image",
                fileName: "menu_image.jpg",
                mimeType: "image/jpeg"
            )
            return .uploadMultipart([formData])

        case .createMenu(_, let request):
            return .requestJSONEncodable(request)

        case .updateMenu(_, let request):
            return .requestJSONEncodable(request)
        }
    }
}
