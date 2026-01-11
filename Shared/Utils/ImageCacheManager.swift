//
//  ImageCacheManager.swift
//  Odaeri
//
//  Created by 박성훈 on 12/30/25.
//

import UIKit
import Combine
import Moya

final class ImageCacheManager {
    static let shared = ImageCacheManager()

    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCache = DiskCacheManager.shared
    private let provider = MoyaProvider<MediaAPI>()

    // 중복 요청 방지를 위한 진행 중인 요청 추적
    private var inFlightRequests: [String: AnyPublisher<UIImage, Error>] = [:]
    private let requestQueue = DispatchQueue(label: "com.odaeri.imagecache.request", attributes: .concurrent)

    // 스레드 관리를 위한 스케줄러
    private let imageDecodingScheduler = DispatchQueue(label: "com.odaeri.imagecache.decoding", qos: .userInitiated)

    private init() {
        configureMemoryCache()
    }

    private func configureMemoryCache() {
        // 최대 100개 이미지 저장
        memoryCache.countLimit = 100

        // 최대 50MB 메모리 사용
        memoryCache.totalCostLimit = 50 * 1024 * 1024

        // 메모리 경고 시 캐시 비우기
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearMemoryCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    @objc private func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }

    func loadImage(url: String, targetSize: CGSize? = nil) -> AnyPublisher<UIImage, Error> {
        let cacheKey = NSString(string: url)

        // 1. 메모리 캐시 확인
        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            return Just(cachedImage)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        // 2. 디스크 캐시 확인
        return Future<UIImage?, Error> { [weak self] promise in
            self?.diskCache.loadImage(for: url) { image in
                promise(.success(image))
            }
        }
        .flatMap { [weak self] diskImage -> AnyPublisher<UIImage, Error> in
            guard let self = self else {
                return Fail(error: ImageCacheError.invalidImageData)
                    .eraseToAnyPublisher()
            }

            // 2-1. 디스크 캐시에 있으면 메모리에도 저장하고 반환
            if let diskImage = diskImage {
                let cost = Int(diskImage.jpegData(compressionQuality: 1.0)?.count ?? 0)
                self.memoryCache.setObject(diskImage, forKey: cacheKey, cost: cost)

                return Just(diskImage)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }

            // 3. 네트워크 요청 (디스크 캐시 없음)
            return self.loadFromNetwork(url: url, cacheKey: cacheKey, targetSize: targetSize)
        }
        .eraseToAnyPublisher()
    }

    private func loadFromNetwork(url: String, cacheKey: NSString, targetSize: CGSize?) -> AnyPublisher<UIImage, Error> {
        // 진행 중인 요청 확인 (중복 요청 방지)
        return requestQueue.sync(flags: .barrier) { [weak self] () -> AnyPublisher<UIImage, Error> in
            guard let self = self else {
                return Fail(error: ImageCacheError.invalidImageData)
                    .eraseToAnyPublisher()
            }

            // 3-1. 이미 진행 중인 요청이 있으면 해당 Publisher 반환
            if let existingPublisher = self.inFlightRequests[url] {
                return existingPublisher
            }

            // 3-2. ETag 확인
            let etag = self.diskCache.loadETag(for: url)

            // 3-3. 새 네트워크 요청 생성
            let publisher = self.provider.requestPublisher(.fetchImage(path: url, etag: etag))
                .subscribe(on: self.imageDecodingScheduler) // 백그라운드에서 네트워크 요청
                .tryMap { [weak self] (response: Response) -> UIImage in
                    guard let self = self else {
                        throw ImageCacheError.invalidImageData
                    }

                    // 304 Not Modified 응답 처리
                    if response.statusCode == 304 {
                        // 디스크 캐시에서 이미지 로드 (동기적으로)
                        return try self.loadImageFromDiskSync(url: url, cacheKey: cacheKey)
                    }

                    // 200 OK 응답 처리 (다운샘플링 적용)
                    let image: UIImage

                    if let targetSize = targetSize {
                        // 다운샘플링 적용
                        if let downsampledImage = ImageDownsampler.downsample(
                            imageData: response.data,
                            to: targetSize
                        ) {
                            image = downsampledImage
                        } else {
                            // 다운샘플링 실패 시 원본 사용
                            guard let originalImage = UIImage(data: response.data) else {
                                throw ImageCacheError.invalidImageData
                            }
                            image = originalImage
                        }
                    } else {
                        // targetSize가 없으면 원본 사용
                        guard let originalImage = UIImage(data: response.data) else {
                            throw ImageCacheError.invalidImageData
                        }
                        image = originalImage
                    }

                    // ETag 추출
                    let etag = response.response?.allHeaderFields["ETag"] as? String

                    // 메모리 캐시에 저장
                    let cost = Int(image.jpegData(compressionQuality: 1.0)?.count ?? 0)
                    self.memoryCache.setObject(image, forKey: cacheKey, cost: cost)

                    // 디스크 캐시에 저장 (원본 데이터)
                    self.diskCache.saveImage(image, for: url, etag: etag)

                    return image
                }
                .receive(on: DispatchQueue.main) // 메인 스레드에서 결과 전달
                .handleEvents(
                    receiveCompletion: { [weak self] _ in
                        // 요청 완료 시 inFlightRequests에서 제거
                        self?.requestQueue.async(flags: .barrier) {
                            self?.inFlightRequests.removeValue(forKey: url)
                        }
                    },
                    receiveCancel: { [weak self] in
                        // 요청 취소 시에도 inFlightRequests에서 제거
                        self?.requestQueue.async(flags: .barrier) {
                            self?.inFlightRequests.removeValue(forKey: url)
                        }
                    }
                )
                .share() // 여러 구독자가 같은 요청을 공유
                .eraseToAnyPublisher()

            // 3-4. inFlightRequests에 저장
            self.inFlightRequests[url] = publisher

            return publisher
        }
    }

    /// 304 응답 시 디스크에서 동기적으로 이미지 로드
    /// - Note: imageDecodingScheduler(백그라운드)에서만 호출됩니다.
    private func loadImageFromDiskSync(url: String, cacheKey: NSString) throws -> UIImage {
        // DiskCacheManager의 동기 메서드 사용 (이미 백그라운드 스레드에서 실행 중)
        guard let image = diskCache.loadImageSync(for: url) else {
            throw ImageCacheError.invalidImageData
        }

        // 메모리 캐시에도 저장
        let cost = Int(image.jpegData(compressionQuality: 1.0)?.count ?? 0)
        memoryCache.setObject(image, forKey: cacheKey, cost: cost)

        return image
    }

    func clearCache() {
        memoryCache.removeAllObjects()
        diskCache.clearCache()
        requestQueue.async(flags: .barrier) { [weak self] in
            self?.inFlightRequests.removeAll()
        }
    }

    func removeImage(for url: String) {
        let cacheKey = NSString(string: url)
        memoryCache.removeObject(forKey: cacheKey)
        diskCache.removeImage(for: url)
        requestQueue.async(flags: .barrier) { [weak self] in
            self?.inFlightRequests.removeValue(forKey: url)
        }
    }

    func cacheImage(_ image: UIImage, forKey key: String) {
        let cacheKey = NSString(string: key)
        let cost = Int(image.jpegData(compressionQuality: 1.0)?.count ?? 0)
        memoryCache.setObject(image, forKey: cacheKey, cost: cost)
    }

    func getCachedImage(forKey key: String) -> UIImage? {
        let cacheKey = NSString(string: key)
        return memoryCache.object(forKey: cacheKey)
    }
}

// MARK: - Error
enum ImageCacheError: Error {
    case invalidImageData
    case networkError(Error)

    var localizedDescription: String {
        switch self {
        case .invalidImageData:
            return "유효하지 않은 이미지 데이터입니다."
        case .networkError(let error):
            return "네트워크 오류: \(error.localizedDescription)"
        }
    }
}
