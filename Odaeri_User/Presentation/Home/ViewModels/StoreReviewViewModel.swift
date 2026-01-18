//
//  StoreReviewViewModel.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/18/26.
//

import Foundation
import Combine

final class StoreReviewViewModel: BaseViewModel, ViewModelType {
    private let storeId: String

    init(storeId: String) {
        self.storeId = storeId
    }

    struct Input {
        let viewDidLoad: AnyPublisher<Void, Never>
    }

    struct Output {
        let storeId: AnyPublisher<String, Never>
    }

    func transform(input: Input) -> Output {
        let storeIdPublisher = input.viewDidLoad
            .map { [storeId] in storeId }
            .eraseToAnyPublisher()

        return Output(storeId: storeIdPublisher)
    }
}
