//
//  ImageViewerDismissAnimator.swift
//  Odaeri
//
//  Created by 박성훈 on 01/21/26.
//

import UIKit

final class ImageViewerDismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private weak var sourceViewController: ImageViewerTransitionSource?

    init(sourceViewController: ImageViewerTransitionSource?) {
        self.sourceViewController = sourceViewController
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from) as? ImageViewerViewController else {
            transitionContext.completeTransition(false)
            return
        }

        let currentIndex = fromVC.currentIndex

        guard let destinationImageView = sourceViewController?.imageView(at: currentIndex),
              let destinationFrame = sourceViewController?.frameForImage(at: currentIndex),
              let sourceImageView = fromVC.imageView(at: currentIndex),
              let sourceImage = sourceImageView.image else {
            UIView.animate(withDuration: 0.3) {
                fromVC.view.alpha = 0
            } completion: { _ in
                transitionContext.completeTransition(true)
            }
            return
        }

        let containerView = transitionContext.containerView

        let transitionImageView = UIImageView(image: sourceImage)
        transitionImageView.contentMode = .scaleAspectFill
        transitionImageView.clipsToBounds = true

        if let sourceFrame = fromVC.frameForImage(at: currentIndex) {
            transitionImageView.frame = sourceFrame
        } else {
            transitionImageView.frame = calculateCurrentFrame(for: sourceImage.size, in: fromVC.view.bounds)
        }

        containerView.addSubview(transitionImageView)

        fromVC.view.alpha = 0
        destinationImageView.alpha = 0

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0,
            options: [.curveEaseInOut]
        ) {
            transitionImageView.frame = destinationFrame
        } completion: { finished in
            transitionImageView.removeFromSuperview()
            destinationImageView.alpha = 1.0
            transitionContext.completeTransition(finished)
        }
    }

    private func calculateCurrentFrame(for imageSize: CGSize, in containerFrame: CGRect) -> CGRect {
        let imageAspectRatio = imageSize.width / imageSize.height
        let containerAspectRatio = containerFrame.width / containerFrame.height

        let targetSize: CGSize
        if imageAspectRatio > containerAspectRatio {
            targetSize = CGSize(
                width: containerFrame.width,
                height: containerFrame.width / imageAspectRatio
            )
        } else {
            targetSize = CGSize(
                width: containerFrame.height * imageAspectRatio,
                height: containerFrame.height
            )
        }

        let targetOrigin = CGPoint(
            x: (containerFrame.width - targetSize.width) / 2,
            y: (containerFrame.height - targetSize.height) / 2
        )

        return CGRect(origin: targetOrigin, size: targetSize)
    }
}
