//
//  MediaUploadManager.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/14/26.
//

import Combine
import UIKit
import Moya

enum UploadItem {
    case image(UIImage)
    case imageURL(URL)
    case video(URL)
    case file(URL)
}

struct UploadResultItem {
    let originalIndex: Int
    let urls: [String]
    let isThumbnailAndVideo: Bool
}

final class MediaUploadManager {
    static let shared = MediaUploadManager(
        processingService: .shared,
        uploadService: MediaUploadService()
    )

    private let processingService: MediaProcessingService
    private let uploadService: MediaUploadService

    private let semaphore = DispatchSemaphore(value: 1)
    private let progressSubject = CurrentValueSubject<Double, Never>(0)
    private var cancellables = Set<AnyCancellable>()

    private init(processingService: MediaProcessingService, uploadService: MediaUploadService) {
        self.processingService = processingService
        self.uploadService = uploadService
    }

    func progressPublisher() -> AnyPublisher<Double, Never> {
        progressSubject.eraseToAnyPublisher()
    }

    func uploadMedias(
        _ items: [UploadItem],
        config: UploadConfig,
        roomId: String? = nil,
        progress: @escaping (Double) -> Void
    ) -> AnyPublisher<[String], MediaError> {
        Future<[String], MediaError> { [weak self] promise in
            guard let self = self else { return }

            _Concurrency.Task {
                self.semaphore.wait()

                var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
                backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "MediaUploadTask") {
                    self.endBackgroundTask(&backgroundTaskID)
                }

                var tempFiles: [URL] = []
                var results: [UploadResultItem] = []

                do {
                    for (index, item) in items.enumerated() {
                        let result = try await self.processAndUploadItem(
                            item,
                            at: index,
                            config: config,
                            roomId: roomId,
                            tempFiles: &tempFiles,
                            progress: progress
                        )
                        results.append(result)
                    }

                    let orderedURLs = self.buildOrderedURLs(from: results)

                    self.cleanupFiles(tempFiles: tempFiles, taskID: &backgroundTaskID)
                    promise(.success(orderedURLs))

                } catch {
                    self.cleanupFiles(tempFiles: tempFiles, taskID: &backgroundTaskID)
                    promise(.failure((error as? MediaError) ?? .unknown))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private func processAndUploadItem(
        _ item: UploadItem,
        at index: Int,
        config: UploadConfig,
        roomId: String?,
        tempFiles: inout [URL],
        progress: @escaping (Double) -> Void
    ) async throws -> UploadResultItem {
        switch item {
        case .image(let uiImage):
            let processedURL = try await processingService.processImage(uiImage, config: config)
            tempFiles.append(processedURL)

            let uploadedURLs = try await uploadSingleFile(
                processedURL,
                config: config,
                roomId: roomId,
                progress: progress
            )

            return UploadResultItem(
                originalIndex: index,
                urls: uploadedURLs,
                isThumbnailAndVideo: false
            )

        case .imageURL(let url):
            let processedURL = try await processingService.processImageFromURL(url, config: config)
            tempFiles.append(processedURL)

            let uploadedURLs = try await uploadSingleFile(
                processedURL,
                config: config,
                roomId: roomId,
                progress: progress
            )

            return UploadResultItem(
                originalIndex: index,
                urls: uploadedURLs,
                isThumbnailAndVideo: false
            )

        case .video(let url):
            let compressedURL = try await processingService.compressVideo(at: url, config: config)
            tempFiles.append(compressedURL)

            let thumbnailData = try await processingService.generateThumbnail(at: compressedURL)

            let thumbnailURL = try saveThumbnailToTempFile(thumbnailData)
            tempFiles.append(thumbnailURL)

            let thumbnailUploadedURLs = try await uploadSingleFile(
                thumbnailURL,
                config: config,
                roomId: roomId,
                progress: progress
            )

            let videoUploadedURLs = try await uploadSingleFile(
                compressedURL,
                config: config,
                roomId: roomId,
                progress: progress
            )

            let combinedURLs = thumbnailUploadedURLs + videoUploadedURLs

            return UploadResultItem(
                originalIndex: index,
                urls: combinedURLs,
                isThumbnailAndVideo: true
            )

        case .file(let url):
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw MediaError.invalidURL
            }

            guard config.isDocumentFile(url) else {
                throw MediaError.invalidFileExtension
            }

            let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64 ?? 0
            guard config.validateFileSize(fileSize) else {
                throw MediaError.fileSizeExceeded(limit: config.maxFileSize)
            }

            let uploadedURLs = try await uploadSingleFile(
                url,
                config: config,
                roomId: roomId,
                progress: progress
            )

            return UploadResultItem(
                originalIndex: index,
                urls: uploadedURLs,
                isThumbnailAndVideo: false
            )
        }
    }

    private func uploadSingleFile(
        _ fileURL: URL,
        config: UploadConfig,
        roomId: String?,
        progress: @escaping (Double) -> Void
    ) async throws -> [String] {
        let mimeType = mimeType(for: fileURL)
        let multipart = MultipartFormData(
            provider: .file(fileURL),
            name: "files",
            fileName: fileURL.lastPathComponent,
            mimeType: mimeType
        )

        return try await withCheckedThrowingContinuation { continuation in
            self.uploadService.upload(
                context: config.context,
                roomId: roomId,
                multiparts: [multipart],
                progress: { [weak self] p in
                    self?.progressSubject.send(p)
                    progress(p)
                }
            )
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        continuation.resume(throwing: self.mapError(error))
                    }
                },
                receiveValue: { urls in
                    continuation.resume(returning: urls)
                }
            )
            .store(in: &self.cancellables)
        }
    }

    private func saveThumbnailToTempFile(_ data: Data) throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MediaUploads", isDirectory: true)

        if !FileManager.default.fileExists(atPath: tempDirectory.path) {
            try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        }

        let fileURL = tempDirectory.appendingPathComponent("thumbnail_\(UUID().uuidString).jpg")
        try data.write(to: fileURL)
        return fileURL
    }

    private func buildOrderedURLs(from results: [UploadResultItem]) -> [String] {
        let sorted = results.sorted { $0.originalIndex < $1.originalIndex }
        return sorted.flatMap { $0.urls }
    }

    private func cleanupFiles(tempFiles: [URL], taskID: inout UIBackgroundTaskIdentifier) {
        cleanupTempFiles(tempFiles)
        endBackgroundTask(&taskID)
        semaphore.signal()
    }

    private func cleanupTempFiles(_ urls: [URL]) {
        urls.forEach { url in
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func endBackgroundTask(_ taskID: inout UIBackgroundTaskIdentifier) {
        if taskID != .invalid {
            UIApplication.shared.endBackgroundTask(taskID)
            taskID = .invalid
        }
    }

    private func mimeType(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "mp4":
            return "video/mp4"
        case "mov":
            return "video/quicktime"
        case "avi":
            return "video/x-msvideo"
        case "mkv":
            return "video/x-matroska"
        case "wmv":
            return "video/x-ms-wmv"
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "webp":
            return "image/webp"
        case "heic":
            return "image/heic"
        case "pdf":
            return "application/pdf"
        default:
            return "application/octet-stream"
        }
    }

    private func mapError(_ error: NetworkError) -> MediaError {
        switch error {
        case .noInternetConnection, .timeout:
            return .networkTimeout
        default:
            return .unknown
        }
    }
}
