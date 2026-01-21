//
//  ImageViewerPresentAnimator.swift
//  Odaeri
//
//  Created by 박성훈 on 01/21/26.
//

import UIKit

final class ImageViewerPresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private weak var sourceViewController: ImageViewerTransitionSource?
    private let initialIndex: Int

    init(sourceViewController: ImageViewerTransitionSource?, initialIndex: Int) {
        self.sourceViewController = sourceViewController
        self.initialIndex = initialIndex
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .to) as? ImageViewerViewController else {
            transitionContext.completeTransition(false)
            return
        }

        guard let sourceImageView = sourceViewController?.imageView(at: initialIndex),
              let sourceFrame = sourceViewController?.frameForImage(at: initialIndex),
              let sourceImage = sourceImageView.image else {

            let containerView = transitionContext.containerView
            let finalFrame = transitionContext.finalFrame(for: toVC)

            toVC.view.frame = finalFrame
            toVC.view.alpha = 0
            containerView.addSubview(toVC.view)

            UIView.animate(withDuration: 0.3) {
                toVC.view.alpha = 1.0
            } completion: { finished in
                transitionContext.completeTransition(finished)
            }
            return
        }

        let containerView = transitionContext.containerView
        let finalFrame = transitionContext.finalFrame(for: toVC)

        toVC.view.frame = finalFrame
        toVC.view.alpha = 0

        let transitionImageView = UIImageView(image: sourceImage)
        transitionImageView.contentMode = .scaleAspectFill
        transitionImageView.clipsToBounds = true
        transitionImageView.frame = sourceFrame

        containerView.addSubview(toVC.view)
        containerView.addSubview(transitionImageView)

        sourceImageView.alpha = 0

        let targetFrame = calculateTargetFrame(for: sourceImage.size, in: finalFrame)

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0,
            options: [.curveEaseInOut]
        ) {
            transitionImageView.frame = targetFrame
            toVC.view.alpha = 1.0
        } completion: { finished in
            transitionImageView.removeFromSuperview()
            sourceImageView.alpha = 1.0
            transitionContext.completeTransition(finished)
        }
    }

    private func calculateTargetFrame(for imageSize: CGSize, in containerFrame: CGRect) -> CGRect {
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
