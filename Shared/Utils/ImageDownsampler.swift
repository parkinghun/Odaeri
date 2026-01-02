//
//  ImageDownsampler.swift
//  Odaeri
//
//  Created by 박성훈 on 12/30/25.
//

import UIKit

/// 이미지 다운샘플링 유틸리티
///
/// 고해상도 이미지를 메모리 효율적으로 로드하기 위한 다운샘플링 기능을 제공합니다.
/// CGImageSource를 사용하여 디코딩 시점에 이미지 크기를 조절하므로,
/// 원본 해상도를 메모리에 올리지 않고 타겟 크기만큼만 로드합니다.
///
/// ### 메모리 절약 효과 예시
/// - 원본: 4000x4000 (64MB)
/// - UIImageView: 100x100
/// - 다운샘플링 후: 200x200 (Retina 대응, 약 0.16MB)
/// - **메모리 절약: 99.75%**
enum ImageDownsampler {
    /// 이미지 데이터를 다운샘플링하여 UIImage 생성
    ///
    /// - Parameters:
    ///   - imageData: 원본 이미지 데이터
    ///   - pointSize: 타겟 크기 (포인트 단위)
    ///   - scale: 화면 스케일 (기본값: 현재 화면 스케일)
    /// - Returns: 다운샘플링된 UIImage (실패 시 nil)
    static func downsample(
        imageData: Data,
        to pointSize: CGSize,
        scale: CGFloat = UIScreen.main.scale
    ) -> UIImage? {
        // ImageSource 생성 옵션 (캐시하지 않음)
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary

        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, imageSourceOptions) else {
            return nil
        }

        // 픽셀 단위로 변환 (Retina 디스플레이 대응)
        let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale

        // 다운샘플링 옵션
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,  // 항상 썸네일 생성
            kCGImageSourceShouldCacheImmediately: true,          // 즉시 디코딩 (백그라운드 스레드에서)
            kCGImageSourceCreateThumbnailWithTransform: true,    // EXIF 방향 정보 적용
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels  // 최대 픽셀 크기
        ] as CFDictionary

        // 다운샘플링된 이미지 생성
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }

        return UIImage(cgImage: downsampledImage)
    }

    /// 이미지 데이터를 다운샘플링하여 UIImage 생성 (자동 크기 계산)
    ///
    /// - Parameters:
    ///   - imageData: 원본 이미지 데이터
    ///   - targetView: 타겟 UIImageView (뷰의 bounds 기준)
    /// - Returns: 다운샘플링된 UIImage (실패 시 nil)
    static func downsample(imageData: Data, for targetView: UIImageView) -> UIImage? {
        let targetSize = targetView.bounds.size

        // 뷰 크기가 없으면 기본 크기 사용
        guard targetSize.width > 0 && targetSize.height > 0 else {
            return downsample(imageData: imageData, to: CGSize(width: 200, height: 200))
        }

        return downsample(imageData: imageData, to: targetSize, scale: targetView.contentScaleFactor)
    }

    /// 원본 이미지의 크기 정보 조회 (메모리에 로드하지 않음)
    ///
    /// - Parameter imageData: 이미지 데이터
    /// - Returns: 이미지 크기 (픽셀 단위)
    static func getImageSize(from imageData: Data) -> CGSize? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary

        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, imageSourceOptions),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
              let height = properties[kCGImagePropertyPixelHeight] as? CGFloat else {
            return nil
        }

        return CGSize(width: width, height: height)
    }

    /// 다운샘플링이 필요한지 판단
    ///
    /// - Parameters:
    ///   - imageSize: 원본 이미지 크기 (픽셀)
    ///   - targetSize: 타겟 크기 (포인트)
    ///   - scale: 화면 스케일
    /// - Returns: 다운샘플링 필요 여부
    static func shouldDownsample(
        imageSize: CGSize,
        targetSize: CGSize,
        scale: CGFloat = UIScreen.main.scale
    ) -> Bool {
        let targetPixelSize = CGSize(
            width: targetSize.width * scale,
            height: targetSize.height * scale
        )

        // 원본이 타겟보다 1.5배 이상 크면 다운샘플링
        let threshold: CGFloat = 1.5
        return imageSize.width > targetPixelSize.width * threshold ||
               imageSize.height > targetPixelSize.height * threshold
    }
}
