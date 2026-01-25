//
//  CheckVideoSavedUseCase.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/25/26.
//

import Foundation
import Combine

protocol CheckVideoSavedUseCase {
    func execute(videoId: String) -> AnyPublisher<Bool, Never>
}

final class DefaultCheckVideoSavedUseCase: CheckVideoSavedUseCase {
    private let repository: RealmSavedVideoRepository

    init(repository: RealmSavedVideoRepository = .shared) {
        self.repository = repository
    }

    func execute(videoId: String) -> AnyPublisher<Bool, Never> {
        return repository.isSaved(videoId: videoId)
    }
}
