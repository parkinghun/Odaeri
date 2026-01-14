//
//  MediaUploadConfig.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/14/26.
//

import Foundation
import AVFoundation

/// 비즈니스 정책에 따른 영상 압축 해상도 정의
enum VideoResolution: String {
    case low
    case medium
    case high

    var preset: String {
        switch self {
        case .low:
            return AVAssetExportPreset640x480
        case .medium:
            return AVAssetExportPreset1280x720
        case .high:
            return AVAssetExportPreset1920x1080
        }
    }
}

enum UploadContext {
    case chat
    case community
}

struct UploadConfig {
    let context: UploadContext
    let resolution: VideoResolution
    let maxFileSize: Int64

    static let chatDefault = UploadConfig(
        context: .chat,
        resolution: .medium,
        maxFileSize: 5 * 1024 * 1024
    )

    static let communityDefault = UploadConfig(
        context: .community,
        resolution: .medium,
        maxFileSize: 5 * 1024 * 1024
    )
}

enum MediaError: LocalizedError {
    case compressionFailed
    case fileSizeExceeded(limit: Int64)
    case networkTimeout
    case insufficientStorage
    case invalidURL
    case unknown

    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "동영상 압축에 실패했습니다."
        case .fileSizeExceeded(let limit):
            return "파일 용량이 제한(\(limit.toMBString()))을 초과했습니다."
        case .networkTimeout:
            return "네트워크 요청 시간이 초과되었습니다."
        case .insufficientStorage:
            return "기기의 저장 공간이 부족합니다."
        case .invalidURL:
            return "유효하지 않은 파일 경로입니다."
        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}

private extension Int64 {
    func toMBString() -> String {
        let mbValue = Double(self) / 1024.0 / 1024.0
        return String(format: "%.0fMB", mbValue)
    }
}
