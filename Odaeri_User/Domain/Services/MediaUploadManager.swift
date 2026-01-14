//
//  MediaUploadManager.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/14/26.
//

import Combine
import UIKit
import Moya

final class MediaUploadManager {
    static let shared = MediaUploadManager(
        processingService: .shared,
        uploadService: MediaUploadService()
    )

    private let processingService: MediaProcessingService
    private let uploadService: MediaUploadService
    
    // 순차적 실행을 위한 세마포어
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

    func uploadVideo(
        sourceURL: URL,
        config: UploadConfig,
        roomId: String? = nil
    ) -> AnyPublisher<MediaUploadResult, MediaError> {
        Future<MediaUploadResult, MediaError> { [weak self] promise in
            guard let self = self else { return }

            _Concurrency.Task {
                // 1. 순서 보장을 위한 대기
                self.semaphore.wait()

                // 2. 백그라운드 작업 시작
                var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
                backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "MediaUploadTask") {
                    // 시스템에 의해 작업 시간이 만료된 경우 (안전을 위한 처리)
                    self.endBackgroundTask(&backgroundTaskID)
                }

                var compressedURL: URL?

                do {
                    // 3. 비디오 압축 (MainActor를 무시하고 백그라운드에서 실행)
                    let finalURL = try await self.processingService.compressVideo(at: sourceURL, config: config)
                    compressedURL = finalURL
                    
                    // 4. 썸네일 생성
                    let thumbnailData = try await self.processingService.generateThumbnail(at: finalURL)
                    
                    // 5. [메모리 효율] .file 제공자 사용 / [서버 스펙] name: "files" 사용
                    let multipart = MultipartFormData(
                        provider: .file(finalURL),
                        name: "files",
                        fileName: finalURL.lastPathComponent,
                        mimeType: "video/mp4"
                    )

                    // 6. 업로드 실행
                    self.uploadService.upload(
                        context: config.context,
                        roomId: roomId,
                        multiparts: [multipart],
                        progress: { [weak self] p in self?.progressSubject.send(p) }
                    )
                    .sink(receiveCompletion: { [weak self] completion in
                        if case .failure(let error) = completion {
                            promise(.failure(self?.mapError(error) ?? .unknown))
                        }
                        // 완료 시 자원 정리 (실패 시)
                        self?.cleanup(url: compressedURL, taskID: &backgroundTaskID)
                    }, receiveValue: { [weak self] urls in
                        // 성공 결과 반환
                        promise(.success(MediaUploadResult(
                            uploadedURLs: urls,
                            thumbnailData: thumbnailData,
                            localTempURL: finalURL
                        )))
                        // 완료 시 자원 정리 (성공 시)
                        self?.cleanup(url: compressedURL, taskID: &backgroundTaskID)
                    })
                    .store(in: &self.cancellables)

                } catch {
                    // 압축이나 썸네일 생성 중 에러 발생 시 정리
                    self.cleanup(url: compressedURL, taskID: &backgroundTaskID)
                    promise(.failure((error as? MediaError) ?? .unknown))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // ✅ 자원 정리 로직 통합 (중복 코드 제거)
    private func cleanup(url: URL?, taskID: inout UIBackgroundTaskIdentifier) {
        // 임시 파일 삭제
        if let url = url {
            try? FileManager.default.removeItem(at: url)
        }
        
        // 백그라운드 태스크 종료
        endBackgroundTask(&taskID)
        
        // 세마포어 해제 (다음 업로드 허용)
        self.semaphore.signal()
    }

    private func endBackgroundTask(_ taskID: inout UIBackgroundTaskIdentifier) {
        if taskID != .invalid {
            UIApplication.shared.endBackgroundTask(taskID)
            taskID = .invalid
        }
    }

    private func mapError(_ error: NetworkError) -> MediaError {
        switch error {
        case .noInternetConnection, .timeout: return .networkTimeout
        default: return .unknown
        }
    }
}
