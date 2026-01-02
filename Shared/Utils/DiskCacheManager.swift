//
//  DiskCacheManager.swift
//  Odaeri
//
//  Created by 박성훈 on 12/30/25.
//

import UIKit
import CryptoKit

final class DiskCacheManager {
    static let shared = DiskCacheManager()

    // MARK: - Properties
    private let fileManager = FileManager.default
    private let diskQueue = DispatchQueue(label: "com.odaeri.diskcache", qos: .utility)
    private let cacheDirectory: URL

    // ETag 저장소 (UserDefaults)
    private let etagKey = "com.odaeri.image.etags"
    private var etagStorage: [String: String] {
        get {
            UserDefaults.standard.dictionary(forKey: etagKey) as? [String: String] ?? [:]
        }
        set {
            UserDefaults.standard.set(newValue, forKey: etagKey)
        }
    }

    // 캐시 정리 설정
    private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60 // 7일
    private let maxCacheSize: Int64 = 100 * 1024 * 1024 // 100MB

    // MARK: - Initialization
    private init() {
        // Library/Caches 디렉토리 경로
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheDirectory = cachesDirectory.appendingPathComponent("ImageCache", isDirectory: true)

        // 디렉토리 생성 및 정리
        createCacheDirectoryIfNeeded()
        cleanOldCacheIfNeeded()
    }

    private func createCacheDirectoryIfNeeded() {
        diskQueue.async { [weak self] in
            guard let self = self else { return }

            if !self.fileManager.fileExists(atPath: self.cacheDirectory.path) {
                try? self.fileManager.createDirectory(
                    at: self.cacheDirectory,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            }
        }
    }

    /// 앱 시작 시 오래된 캐시 정리
    private func cleanOldCacheIfNeeded() {
        diskQueue.async { [weak self] in
            guard let self = self else { return }

            self.removeExpiredFiles()
            self.trimCacheSizeIfNeeded()
        }
    }

    // MARK: - URL Hashing
    /// URL을 SHA256 해시로 변환하여 안전한 파일명 생성
    private func hashedFileName(for url: String) -> String {
        return url.sha256()
    }

    /// 파일 경로 생성
    private func fileURL(for url: String) -> URL {
        let fileName = hashedFileName(for: url)
        return cacheDirectory.appendingPathComponent(fileName)
    }

    // MARK: - Image Cache
    /// 디스크에서 이미지 조회 (비동기)
    func loadImage(for url: String, completion: @escaping (UIImage?) -> Void) {
        diskQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let image = self.loadImageSyncInternal(for: url)

            DispatchQueue.main.async { completion(image) }
        }
    }

    /// 디스크에서 이미지 조회 (동기 - diskQueue.sync 래퍼)
    /// - Note: 백그라운드 스레드에서 안전하게 호출 가능합니다.
    func loadImageSync(for url: String) -> UIImage? {
        return diskQueue.sync { [weak self] in
            self?.loadImageSyncInternal(for: url)
        }
    }

    /// 디스크에서 이미지 조회 (내부 동기 메서드)
    private func loadImageSyncInternal(for url: String) -> UIImage? {
        let fileURL = fileURL(for: url)

        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }

        // 파일 접근 시간 업데이트 (LRU 관리용)
        updateAccessDate(for: fileURL)

        return image
    }

    /// 디스크에 이미지 저장
    func saveImage(_ image: UIImage, for url: String, etag: String? = nil, completion: (() -> Void)? = nil) {
        diskQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion?() }
                return
            }

            let fileURL = self.fileURL(for: url)

            // 이미지를 JPEG 데이터로 변환 (압축률 0.8)
            guard let data = image.jpegData(compressionQuality: 0.8) else {
                DispatchQueue.main.async { completion?() }
                return
            }

            // 파일 저장
            try? data.write(to: fileURL)

            // ETag 저장
            if let etag = etag {
                self.saveETag(etag, for: url)
            }

            DispatchQueue.main.async { completion?() }
        }
    }

    /// 디스크에서 이미지 삭제
    func removeImage(for url: String) {
        diskQueue.async { [weak self] in
            guard let self = self else { return }

            let fileURL = self.fileURL(for: url)

            try? self.fileManager.removeItem(at: fileURL)

            // ETag도 삭제
            self.removeETag(for: url)
        }
    }

    /// 모든 디스크 캐시 삭제
    func clearCache(completion: (() -> Void)? = nil) {
        diskQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion?() }
                return
            }

            // 캐시 디렉토리 삭제 후 재생성
            try? self.fileManager.removeItem(at: self.cacheDirectory)
            self.createCacheDirectoryIfNeeded()

            // ETag 전체 삭제
            self.etagStorage = [:]

            DispatchQueue.main.async { completion?() }
        }
    }

    // MARK: - ETag Management
    /// ETag 저장
    private func saveETag(_ etag: String, for url: String) {
        let key = hashedFileName(for: url)
        var storage = etagStorage
        storage[key] = etag
        etagStorage = storage
    }

    /// ETag 조회
    func loadETag(for url: String) -> String? {
        let key = hashedFileName(for: url)
        return etagStorage[key]
    }

    /// ETag 삭제
    private func removeETag(for url: String) {
        let key = hashedFileName(for: url)
        var storage = etagStorage
        storage.removeValue(forKey: key)
        etagStorage = storage
    }

    // MARK: - Cache Size & Management
    /// 캐시 크기 계산 (바이트)
    func getCacheSize(completion: @escaping (Int64) -> Void) {
        diskQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion(0) }
                return
            }

            var totalSize: Int64 = 0

            guard let enumerator = self.fileManager.enumerator(at: self.cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
                DispatchQueue.main.async { completion(0) }
                return
            }

            for case let fileURL as URL in enumerator {
                guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                      let fileSize = resourceValues.fileSize else {
                    continue
                }
                totalSize += Int64(fileSize)
            }

            DispatchQueue.main.async { completion(totalSize) }
        }
    }

    /// 파일 접근 시간 업데이트
    private func updateAccessDate(for fileURL: URL) {
        let now = Date()
        try? fileManager.setAttributes(
            [.modificationDate: now],
            ofItemAtPath: fileURL.path
        )
    }

    /// 만료된 파일 삭제 (maxCacheAge 이상 지난 파일)
    private func removeExpiredFiles() {
        let expirationDate = Date().addingTimeInterval(-maxCacheAge)

        guard let enumerator = fileManager.enumerator(
            at: cacheDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ) else {
            return
        }

        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]),
                  let modificationDate = resourceValues.contentModificationDate else {
                continue
            }

            // 만료된 파일 삭제
            if modificationDate < expirationDate {
                try? fileManager.removeItem(at: fileURL)

                // 해당 파일의 ETag도 삭제
                let fileName = fileURL.lastPathComponent
                removeETagByFileName(fileName)
            }
        }
    }

    /// 캐시 크기가 maxCacheSize를 초과하면 오래된 파일부터 삭제
    private func trimCacheSizeIfNeeded() {
        var totalSize: Int64 = 0
        var files: [(url: URL, size: Int64, date: Date)] = []

        guard let enumerator = fileManager.enumerator(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
        ) else {
            return
        }

        // 모든 파일의 정보 수집
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]),
                  let fileSize = resourceValues.fileSize,
                  let modificationDate = resourceValues.contentModificationDate else {
                continue
            }

            let size = Int64(fileSize)
            totalSize += size
            files.append((url: fileURL, size: size, date: modificationDate))
        }

        // 크기 제한 초과하지 않으면 종료
        guard totalSize > maxCacheSize else {
            return
        }

        // 오래된 파일부터 정렬 (LRU)
        files.sort { $0.date < $1.date }

        // 목표 크기 (maxCacheSize의 70%)
        let targetSize = Int64(Double(maxCacheSize) * 0.7)

        // 오래된 파일부터 삭제
        for file in files {
            guard totalSize > targetSize else {
                break
            }

            try? fileManager.removeItem(at: file.url)
            totalSize -= file.size

            // 해당 파일의 ETag도 삭제
            let fileName = file.url.lastPathComponent
            removeETagByFileName(fileName)
        }
    }

    /// 파일명으로 ETag 삭제
    private func removeETagByFileName(_ fileName: String) {
        var storage = etagStorage
        storage.removeValue(forKey: fileName)
        etagStorage = storage
    }
}

// MARK: - String SHA256 Extension
extension String {
    func sha256() -> String {
        let data = Data(self.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02hhx", $0) }.joined()
    }
}
