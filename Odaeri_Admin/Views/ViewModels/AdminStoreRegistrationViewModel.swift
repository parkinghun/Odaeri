//
//  AdminStoreRegistrationViewModel.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 1/18/26.
//

import Foundation
import Combine
import UIKit

final class AdminStoreRegistrationViewModel {
    struct Input {
        let name: AnyPublisher<String, Never>
        let category: AnyPublisher<String, Never>
        let description: AnyPublisher<String, Never>
        let address: AnyPublisher<String, Never>
        let latitude: AnyPublisher<String, Never>
        let longitude: AnyPublisher<String, Never>
        let open: AnyPublisher<String, Never>
        let close: AnyPublisher<String, Never>
        let parkingGuide: AnyPublisher<String, Never>
        let hashTags: AnyPublisher<String, Never>
        let isPicchelin: AnyPublisher<Bool, Never>
        let images: AnyPublisher<[UIImage], Never>
        let submit: AnyPublisher<Void, Never>
    }

    struct Output {
        let isSubmitEnabled: AnyPublisher<Bool, Never>
        let isLoading: AnyPublisher<Bool, Never>
        let error: AnyPublisher<String, Never>
        let storeRegistered: AnyPublisher<StoreEntity, Never>
    }

    private let storeService: AdminStoreService
    private var cancellables = Set<AnyCancellable>()

    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)
    private let errorSubject = PassthroughSubject<String, Never>()
    private let storeRegisteredSubject = PassthroughSubject<StoreEntity, Never>()

    init(storeService: AdminStoreService = AdminStoreService()) {
        self.storeService = storeService
    }

    func transform(input: Input) -> Output {
        let combined = Publishers.CombineLatest4(
            Publishers.CombineLatest(input.name, input.category),
            Publishers.CombineLatest(input.description, input.address),
            Publishers.CombineLatest(input.latitude, input.longitude),
            Publishers.CombineLatest(input.open, input.close)
        )

        let isSubmitEnabled = combined
            .map { nameCategory, descriptionAddress, latLon, openClose in
                let (name, category) = nameCategory
                let (description, address) = descriptionAddress
                let (lat, lon) = latLon
                let (open, close) = openClose
                return !name.isEmpty &&
                    !category.isEmpty &&
                    !description.isEmpty &&
                    !address.isEmpty &&
                    Double(lat) != nil &&
                    Double(lon) != nil &&
                    !open.isEmpty &&
                    !close.isEmpty
            }
            .eraseToAnyPublisher()

        input.submit
            .withLatestFrom(
                Publishers.CombineLatest3(
                    combined,
                    Publishers.CombineLatest3(input.parkingGuide, input.hashTags, input.isPicchelin),
                    input.images
                )
            )
            .sink { [weak self] _, values in
                guard let self else { return }
                let (combinedValues, extra, images) = values
                let (nameCategory, descriptionAddress, latLon, openClose) = combinedValues
                let (name, category) = nameCategory
                let (description, address) = descriptionAddress
                let (latitude, longitude) = latLon
                let (open, close) = openClose
                let (parkingGuide, hashTags, isPicchelin) = extra

                self.registerStore(
                    name: name,
                    category: category,
                    description: description,
                    address: address,
                    latitude: latitude,
                    longitude: longitude,
                    open: open,
                    close: close,
                    parkingGuide: parkingGuide,
                    hashTags: hashTags,
                    isPicchelin: isPicchelin,
                    images: images
                )
            }
            .store(in: &cancellables)

        return Output(
            isSubmitEnabled: isSubmitEnabled,
            isLoading: isLoadingSubject.eraseToAnyPublisher(),
            error: errorSubject.eraseToAnyPublisher(),
            storeRegistered: storeRegisteredSubject.eraseToAnyPublisher()
        )
    }
}

private extension AdminStoreRegistrationViewModel {
    func registerStore(
        name: String,
        category: String,
        description: String,
        address: String,
        latitude: String,
        longitude: String,
        open: String,
        close: String,
        parkingGuide: String,
        hashTags: String,
        isPicchelin: Bool,
        images: [UIImage]
    ) {
        guard let lat = Double(latitude), let lon = Double(longitude) else {
            errorSubject.send("위치 정보를 확인해주세요.")
            return
        }

        let tags = hashTags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        isLoadingSubject.send(true)

        let uploadPublisher: AnyPublisher<[String], NetworkError>
        if images.isEmpty {
            uploadPublisher = Just([])
                .setFailureType(to: NetworkError.self)
                .eraseToAnyPublisher()
        } else {
            uploadPublisher = storeService.uploadStoreImages(images)
        }

        uploadPublisher
            .flatMap { [weak self] imageUrls -> AnyPublisher<StoreEntity, NetworkError> in
                guard let self else {
                    return Fail(error: NetworkError.unknown(NSError(domain: "AdminStoreRegister", code: -1)))
                        .eraseToAnyPublisher()
                }
                let request = StoreRequest(
                    name: name,
                    category: category,
                    description: description,
                    address: address,
                    longitude: lon,
                    latitude: lat,
                    open: open,
                    close: close,
                    parkingGuide: parkingGuide,
                    storeImageUrls: imageUrls.isEmpty ? nil : imageUrls,
                    hashTags: tags.isEmpty ? nil : tags,
                    isPicchelin: isPicchelin
                )
                return self.storeService.createStore(request: request)
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingSubject.send(false)
                    if case .failure(let error) = completion {
                        self?.errorSubject.send(error.errorDescription)
                    }
                },
                receiveValue: { [weak self] store in
                    self?.storeRegisteredSubject.send(store)
                }
            )
            .store(in: &cancellables)
    }
}

private extension Publisher {
    func withLatestFrom<Other: Publisher>(
        _ other: Other
    ) -> AnyPublisher<(Self.Output, Other.Output), Self.Failure> where Other.Failure == Self.Failure {
        self.flatMap { value in
            other.map { (value, $0) }
        }
        .eraseToAnyPublisher()
    }
}
