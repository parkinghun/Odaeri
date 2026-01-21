//
//  ImageViewerCell.swift
//  Odaeri
//
//  Created by 박성훈 on 01/21/26.
//

import UIKit
import Combine

final class ImageViewerCell: UICollectionViewCell {
    static let identifier = "ImageViewerCell"

    weak var zoomDelegate: ZoomableImageViewDelegate? {
        didSet {
            zoomableImageView.zoomDelegate = zoomDelegate
        }
    }

    private(set) lazy var zoomableImageView = ZoomableImageView()

    private var cancellable: AnyCancellable?

    var imageView: UIImageView {
        return zoomableImageView.imageView
    }

    var imageViewFrame: CGRect? {
        return zoomableImageView.imageViewFrame
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        zoomableImageView.reset()
        zoomableImageView.imageView.image = nil
        cancellable?.cancel()
        cancellable = nil
    }

    private func setupUI() {
        contentView.backgroundColor = .black
        contentView.addSubview(zoomableImageView)

        zoomableImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            zoomableImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            zoomableImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            zoomableImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            zoomableImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    func configure(with imageUrl: String) {
        cancellable = ImageCacheManager.shared.loadImage(url: imageUrl)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("[ImageViewerCell] Failed to load image: \(error)")
                    }
                },
                receiveValue: { [weak self] image in
                    self?.zoomableImageView.configure(with: image)
                }
            )
    }
}
