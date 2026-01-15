//
//  StreamURLCache.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/15/26.
//

import UIKit

final class StreamURLCache {
    static let shared = StreamURLCache()

    private final class StreamWrapper {
        let stream: VideoStreamEntity

        init(_ stream: VideoStreamEntity) {
            self.stream = stream
        }
    }

    private let cache = NSCache<NSString, StreamWrapper>()
    private let syncQueue = DispatchQueue(label: "com.odaeri.streamurlcache.sync", attributes: .concurrent)

    private init() {
        configureCache()
        observeMemoryWarnings()
    }

    private func configureCache() {
        cache.countLimit = 20
        cache.totalCostLimit = 5 * 1024 * 1024
    }

    private func observeMemoryWarnings() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("[StreamURLCache] 메모리 경고 수신, 캐시 전체 삭제")
            self?.removeAll()
        }
    }

    func get(for videoId: String) -> VideoStreamEntity? {
        syncQueue.sync {
            let key = NSString(string: videoId)
            return cache.object(forKey: key)?.stream
        }
    }

    func set(_ stream: VideoStreamEntity, for videoId: String) {
        syncQueue.async(flags: .barrier) { [weak self] in
            let key = NSString(string: videoId)
            let wrapper = StreamWrapper(stream)
            let cost = stream.streamUrl.count + stream.qualities.count * 100
            self?.cache.setObject(wrapper, forKey: key, cost: cost)
            print("[StreamURLCache] 캐시 저장: \(videoId)")
        }
    }

    func remove(for videoId: String) {
        syncQueue.async(flags: .barrier) { [weak self] in
            let key = NSString(string: videoId)
            self?.cache.removeObject(forKey: key)
            print("[StreamURLCache] 캐시 삭제: \(videoId)")
        }
    }

    func removeAll() {
        syncQueue.async(flags: .barrier) { [weak self] in
            self?.cache.removeAllObjects()
        }
    }
}
