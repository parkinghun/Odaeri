//
//  MediaProcessingService.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/14/26.
//

import AVFoundation
import UIKit
import UniformTypeIdentifiers

/// 미디어 파일을 서버 업로드 규격에 맞게 압축·최적화하고, 비즈니스 제약 조건(용량, 저장 공간)을 검증하는 전처리 서비스
final class MediaProcessingService {
    static let shared = MediaProcessingService()

    private enum Constant {
        static let minimumFreeBytes: Int64 = 200 * 1024 * 1024
        static let compressionQuality: CGFloat = 0.8
        static let tempDirectoryName = "MediaUploads"
    }

    private init() {}

    // MARK: - Video Compression (iOS 17+ 전용)
    func compressVideo(at sourceURL: URL, config: UploadConfig) async throws -> URL {
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            throw MediaError.invalidURL
        }

        guard hasSufficientStorage(minimumBytes: Constant.minimumFreeBytes) else {
            throw MediaError.insufficientStorage
        }

        let outputURL = try makeTemporaryVideoURL()
        let asset = AVAsset(url: sourceURL)

        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: config.resolution.preset
        ) else {
            throw MediaError.compressionFailed
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true

        await exportSession.export()
        
        // 결과 검증
        guard exportSession.status == .completed else {
            try? FileManager.default.removeItem(at: outputURL)
            throw MediaError.compressionFailed
        }
        
        // 용량 체크
        let fileSize = try self.fileSize(at: outputURL)
        if fileSize > config.maxFileSize {
            try? FileManager.default.removeItem(at: outputURL)
            throw MediaError.fileSizeExceeded(limit: config.maxFileSize)
        }
        
        return outputURL
    }

    func generateThumbnail(at sourceURL: URL) async throws -> Data {
        let asset = AVAsset(url: sourceURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        let time = CMTime(seconds: 0, preferredTimescale: 600)
        
        let (cgImage, _) = try await generator.image(at: time)
        let uiImage = UIImage(cgImage: cgImage)

        guard let data = uiImage.jpegData(compressionQuality: Constant.compressionQuality) else {
            throw MediaError.unknown
        }
        return data
    }

    private func makeTemporaryVideoURL() throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(Constant.tempDirectoryName, isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: tempDirectory.path) {
            try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        }
        return tempDirectory.appendingPathComponent("video_\(UUID().uuidString).mp4")
    }

    private func hasSufficientStorage(minimumBytes: Int64) -> Bool {
        let path = NSTemporaryDirectory()
        do {
            let values = try URL(fileURLWithPath: path).resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let available = values.volumeAvailableCapacityForImportantUsage {
                return available >= minimumBytes
            }
            return false
        } catch {
            return false
        }
    }

    private func fileSize(at url: URL) throws -> Int64 {
        let values = try url.resourceValues(forKeys: [.fileSizeKey])
        return Int64(values.fileSize ?? 0)
    }
}
