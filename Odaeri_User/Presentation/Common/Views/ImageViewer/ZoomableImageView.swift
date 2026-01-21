//
//  ZoomableImageView.swift
//  Odaeri
//
//  Created by 박성훈 on 01/21/26.
//

import UIKit

protocol ZoomableImageViewDelegate: AnyObject {
    func zoomableImageViewDidChangeZoom(_ zoomableImageView: ZoomableImageView)
}

final class ZoomableImageView: UIScrollView {

    weak var zoomDelegate: ZoomableImageViewDelegate?

    private(set) var imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        return iv
    }()

    private var doubleTapGesture: UITapGestureRecognizer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupScrollView()
        setupImageView()
        setupGestures()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupScrollView() {
        delegate = self
        minimumZoomScale = 1.0
        maximumZoomScale = 3.0
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        backgroundColor = .black
    }

    private func setupImageView() {
        addSubview(imageView)
    }

    private func setupGestures() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
        doubleTapGesture = doubleTap
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if zoomScale > minimumZoomScale {
            setZoomScale(minimumZoomScale, animated: true)
        } else {
            let tapPoint = gesture.location(in: imageView)
            let newZoomScale = maximumZoomScale / 2
            let zoomRect = zoomRectForScale(newZoomScale, center: tapPoint)
            zoom(to: zoomRect, animated: true)
        }
    }

    private func zoomRectForScale(_ scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero

        zoomRect.size.width = imageView.frame.size.width / scale
        zoomRect.size.height = imageView.frame.size.height / scale

        zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0)

        return zoomRect
    }

    func configure(with image: UIImage) {
        imageView.image = image
        setNeedsLayout()
        layoutIfNeeded()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if zoomScale == minimumZoomScale {
            layoutImageView()
        } else {
            centerImageView()
        }
    }

    private func layoutImageView() {
        guard let image = imageView.image else { return }

        let imageSize = image.size
        let scrollViewSize = bounds.size

        guard scrollViewSize.width > 0, scrollViewSize.height > 0 else { return }

        let widthScale = scrollViewSize.width / imageSize.width
        let heightScale = scrollViewSize.height / imageSize.height
        let scale = min(widthScale, heightScale)

        let scaledWidth = imageSize.width * scale
        let scaledHeight = imageSize.height * scale

        imageView.frame = CGRect(
            x: 0,
            y: 0,
            width: scaledWidth,
            height: scaledHeight
        )

        contentSize = imageView.frame.size

        centerImageView()
    }

    private func centerImageView() {
        let offsetX = max((bounds.width - contentSize.width) / 2, 0)
        let offsetY = max((bounds.height - contentSize.height) / 2, 0)

        imageView.frame.origin = CGPoint(x: offsetX, y: offsetY)
    }

    func reset() {
        zoomScale = minimumZoomScale
    }

    var imageViewFrame: CGRect? {
        guard imageView.image != nil else { return nil }
        return convert(imageView.frame, to: superview)
    }
}

// MARK: - UIScrollViewDelegate

extension ZoomableImageView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImageView()
        zoomDelegate?.zoomableImageViewDidChangeZoom(self)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if zoomScale > 1.0 {
            zoomDelegate?.zoomableImageViewDidChangeZoom(self)
        }
    }
}
