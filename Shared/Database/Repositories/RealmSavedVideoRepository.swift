//
//  RealmSavedVideoRepository.swift
//  Odaeri
//
//  Created by 박성훈 on 01/25/26.
//

import Foundation
import RealmSwift
import Combine

final class RealmSavedVideoRepository {
    static let shared = RealmSavedVideoRepository(
        provider: RealmConfigurationProvider(),
        session: UserManager.shared
    )

    private let realmQueue = DispatchQueue(label: "com.odaeri.savedvideo.realm", qos: .userInitiated)
    private let provider: RealmConfigurationProviding
    private let session: SessionProviding

    init(provider: RealmConfigurationProviding, session: SessionProviding) {
        self.provider = provider
        self.session = session
    }

    private func getRealm() throws -> Realm {
        guard let userId = session.currentUserId else {
            throw RealmError.missingUserSession
        }

        let config = try provider.configuration(for: userId)
        return try Realm(configuration: config)
    }

    func saveVideo(videoId: String) -> AnyPublisher<Bool, Never> {
        return Future<Bool, Never> { [weak self] promise in
            self?.realmQueue.async {
                do {
                    let realm = try self?.getRealm()
                    let object = SavedVideoObject(videoId: videoId)

                    try realm?.write {
                        realm?.add(object, update: .all)
                    }

                    promise(.success(true))
                } catch {
                    print("영상 저장 실패: \(error)")
                    promise(.success(false))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func unsaveVideo(videoId: String) -> AnyPublisher<Bool, Never> {
        return Future<Bool, Never> { [weak self] promise in
            self?.realmQueue.async {
                do {
                    let realm = try self?.getRealm()

                    try realm?.write {
                        if let object = realm?.object(
                            ofType: SavedVideoObject.self,
                            forPrimaryKey: videoId
                        ) {
                            realm?.delete(object)
                        }
                    }

                    promise(.success(true))
                } catch {
                    print("영상 저장 취소 실패: \(error)")
                    promise(.success(false))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func isSaved(videoId: String) -> AnyPublisher<Bool, Never> {
        return Future<Bool, Never> { [weak self] promise in
            self?.realmQueue.async {
                do {
                    let realm = try self?.getRealm()
                    let exists = realm?.object(
                        ofType: SavedVideoObject.self,
                        forPrimaryKey: videoId
                    ) != nil

                    promise(.success(exists))
                } catch {
                    promise(.success(false))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchAllSavedVideos() -> AnyPublisher<[String], Never> {
        return Future<[String], Never> { [weak self] promise in
            self?.realmQueue.async {
                do {
                    let realm = try self?.getRealm()
                    let results = realm?.objects(SavedVideoObject.self)
                        .sorted(byKeyPath: "savedAt", ascending: false)

                    let videoIds = results?.map { $0.videoId } ?? []
                    promise(.success(videoIds))
                } catch {
                    promise(.success([]))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
