//
//  UIImageView+Extension.swift
//  Odaeri
//
//  Created by 박성훈 on 12/30/25.
//

import UIKit
import Combine

extension UIImageView {
    // MARK: - Associated Object Keys
    // Objective-C Runtime의 기능을 활용해 extension에서 저장프로퍼티를 추가함
    private struct AssociatedKeys {
        static var imageCancellable: UInt8 = 0
        static var currentImageURL: UInt8 = 0
        static var currentVideoURL: UInt8 = 0
    }

    // MARK: - Private Properties
    private var imageCancellable: AnyCancellable? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.imageCancellable) as? AnyCancellable
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.imageCancellable,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    private var currentImageURL: String? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.currentImageURL) as? String
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.currentImageURL,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    private var currentVideoURL: String? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.currentVideoURL) as? String
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.currentVideoURL,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    // MARK: - Public Methods
    /// 이미지를 비동기로 로드하여 설정합니다.
    ///
    /// 다운샘플링이 자동으로 적용되어 메모리 효율적으로 이미지를 로드합니다.
    /// UIImageView의 bounds 크기에 맞춰 이미지 크기를 최적화합니다.
    ///
    /// - Parameters:
    ///   - url: 이미지 URL
    ///   - placeholder: 로딩 중 표시할 기본 이미지 (옵션)
    ///   - animated: fade-in 애니메이션 적용 여부 (기본값: true)
    ///   - downsample: 다운샘플링 적용 여부 (기본값: true)
    func setImage(
        url: String?,
        placeholder: UIImage? = nil,
        animated: Bool = true,
        downsample: Bool = true
    ) {
        // 1. URL이 없으면 placeholder만 표시
        guard let url = url, !url.isEmpty else {
            self.image = placeholder
            return
        }

        // 2. 같은 URL이면 재요청하지 않음 (최적화)
        if currentImageURL == url {
            return
        }

        // 3. 기존 작업 취소 (다른 URL일 때만)
        if currentImageURL != url {
            cancelImageLoad()
        }

        // 4. 현재 로딩 중인 URL 저장
        currentImageURL = url

        // 5. Placeholder 즉시 표시
        self.image = placeholder

        // 6. 타겟 크기 계산 (다운샘플링용)
        let targetSize: CGSize? = downsample ? calculateTargetSize() : nil

        // 7. 이미지 로드 시작
        imageCancellable = ImageCacheManager.shared.loadImage(url: url, targetSize: targetSize)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("이미지 로드 실패: \(error.localizedDescription)")
                        self?.image = placeholder
                    }
                },
                receiveValue: { [weak self] image in
                    guard let self else { return }

                    // URL이 변경되었는지 확인 (셀 재사용으로 다른 이미지 요청이 들어온 경우)
                    guard self.currentImageURL == url else {
                        return
                    }

                    // 메인 스레드에서 UI 업데이트
                    DispatchQueue.main.async {
                        if animated {
                            UIView.transition(
                                with: self,
                                duration: 0.3,
                                options: .transitionCrossDissolve,
                                animations: {
                                    self.image = image
                                }
                            )
                        } else {
                            self.image = image
                        }
                    }
                }
            )
    }

    /// 다운샘플링을 위한 타겟 크기 계산
    private func calculateTargetSize() -> CGSize? {
        let size = bounds.size

        // 뷰 크기가 0이면 기본 크기 사용
        guard size.width > 0 && size.height > 0 else {
            return CGSize(width: 200, height: 200)
        }

        return size
    }

    /// 진행 중인 이미지 로드 작업을 취소합니다.
    func cancelImageLoad() {
        imageCancellable?.cancel()
        imageCancellable = nil
        currentImageURL = nil
    }

    /// 이미지를 초기화합니다.
    ///
    /// 이 메서드는 3가지 역할을 수행합니다:
    /// 1. **취소(Cancel)**: 현재 진행 중인 네트워크 요청을 즉시 중단합니다.
    /// 2. **초기화(Reset)**: 현재 저장된 currentImageURL 상태를 지웁니다.
    /// 3. **시각적 비움(UI)**: 이미지를 nil 또는 placeholder로 바꿔서 사용자에게 깨끗한 상태를 보여줍니다.
    ///
    /// ### 사용 예시 (셀 재사용 시)
    /// ```swift
    /// class StoreCell: UITableViewCell {
    ///     @IBOutlet weak var storeImageView: UIImageView!
    ///
    ///     override func prepareForReuse() {
    ///         super.prepareForReuse()
    ///         // 셀 재사용 전 이미지 초기화
    ///         storeImageView.resetImage(placeholder: UIImage(named: "placeholder"))
    ///     }
    ///
    ///     func configure(with store: StoreEntity) {
    ///         storeImageView.setImage(url: store.imageURL)
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter placeholder: 초기화 후 표시할 기본 이미지 (옵션)
    /// - Important: UITableViewCell/UICollectionViewCell의 `prepareForReuse()`에서 호출을 권장합니다.
    func resetImage(placeholder: UIImage? = nil) {
        // 1. 취소(Cancel): 진행 중인 네트워크 요청 중단
        cancelImageLoad()
        cancelVideoThumbnail()

        // 2. 초기화(Reset): currentImageURL은 cancelImageLoad()에서 처리됨

        // 3. 시각적 비움(UI): 이미지를 placeholder로 변경
        self.image = placeholder
    }

    /// 비디오 썸네일을 비동기로 로드하여 설정합니다.
    ///
    /// AppMediaService를 통해 썸네일을 자동으로 생성하고 캐싱합니다.
    /// [메모리 캐시 → 디스크 캐시 → 로컬 파일 추출 → 원격 추출] 순서로 최적화됩니다.
    ///
    /// - Parameters:
    ///   - url: 비디오 URL (상대 경로도 자동으로 정규화됨)
    ///   - placeholder: 로딩 중 표시할 기본 이미지 (옵션)
    ///   - animated: fade-in 애니메이션 적용 여부 (기본값: true)
    ///
    /// ### 사용 예시
    /// ```swift
    /// // 이미지처럼 간단하게 사용
    /// imageView.setVideoThumbnail(url: "./data/video.mp4")
    ///
    /// // 셀 재사용 시 자동으로 이전 요청 취소
    /// override func prepareForReuse() {
    ///     super.prepareForReuse()
    ///     imageView.resetImage()  // 비디오 썸네일도 함께 취소됨
    /// }
    /// ```
    func setVideoThumbnail(
        url: String?,
        placeholder: UIImage? = nil,
        animated: Bool = true
    ) {
        guard let url = url, !url.isEmpty else {
            self.image = placeholder
            return
        }

        if currentVideoURL == url {
            return
        }

        if currentVideoURL != url {
            cancelVideoThumbnail()
        }

        currentVideoURL = url
        self.image = placeholder

        AppMediaService.shared.fetchThumbnail(url: url) { [weak self] thumbnail in
            guard let self = self else { return }

            guard self.currentVideoURL == url else {
                return
            }

            DispatchQueue.main.async {
                if animated {
                    UIView.transition(
                        with: self,
                        duration: 0.3,
                        options: .transitionCrossDissolve,
                        animations: {
                            self.image = thumbnail
                        }
                    )
                } else {
                    self.image = thumbnail
                }
            }
        }
    }

    /// 진행 중인 비디오 썸네일 생성 작업을 취소합니다.
    private func cancelVideoThumbnail() {
        if let videoURL = currentVideoURL {
            AppMediaService.shared.cancelThumbnailGeneration(for: videoURL)
        }
        currentVideoURL = nil
    }
}
