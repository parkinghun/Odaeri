//
//  RealmDefaultConfigurationManager.swift
//  Odaeri
//
//  Created by 박성훈 on 2/24/26.
//

import Foundation
import RealmSwift

final class RealmDefaultConfigurationManager {
    static let shared = RealmDefaultConfigurationManager()

    private let provider: RealmConfigurationProviding

    init(provider: RealmConfigurationProviding = RealmConfigurationProvider()) {
        self.provider = provider
    }

    func applyDefaultConfiguration(for userId: String) {
        do {
            let config = try provider.configuration(for: userId)
            Realm.Configuration.defaultConfiguration = config
        } catch {
            print("Realm 기본 설정 실패: \(error)")
        }
    }
}

