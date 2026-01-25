//
//  ToggleSaveVideoUseCase.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/25/26.
//

import Foundation
import Combine

protocol ToggleSaveVideoUseCase {
    func execute(videoId: String, isSaved: Bool) -> AnyPublisher<Bool, Never>
}

final class DefaultToggleSaveVideoUseCase: ToggleSaveVideoUseCase {
    private let repository: RealmSavedVideoRepository

    init(repository: RealmSavedVideoRepository = .shared) {
        self.repository = repository
    }

    func execute(videoId: String, isSaved: Bool) -> AnyPublisher<Bool, Never> {
        if isSaved {
            return repository.saveVideo(videoId: videoId)
        } else {
            return repository.unsaveVideo(videoId: videoId)
        }
    }
}
