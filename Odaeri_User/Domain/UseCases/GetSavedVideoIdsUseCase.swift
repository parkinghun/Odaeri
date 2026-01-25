//
//  GetSavedVideoIdsUseCase.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/26/26.
//

import Foundation
import Combine

protocol GetSavedVideoIdsUseCase {
    func execute() -> AnyPublisher<[String], Never>
}

final class DefaultGetSavedVideoIdsUseCase: GetSavedVideoIdsUseCase {
    private let repository: RealmSavedVideoRepository

    init(repository: RealmSavedVideoRepository = .shared) {
        self.repository = repository
    }

    func execute() -> AnyPublisher<[String], Never> {
        return repository.fetchAllSavedVideos()
    }
}
