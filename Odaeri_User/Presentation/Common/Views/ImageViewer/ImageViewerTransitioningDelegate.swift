//
//  ImageViewerTransitioningDelegate.swift
//  Odaeri
//
//  Created by 박성훈 on 01/21/26.
//

import UIKit

final class ImageViewerTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    private weak var sourceViewController: (UIViewController & ImageViewerTransitionSource)?
    private let initialIndex: Int

    init(sourceViewController: (UIViewController & ImageViewerTransitionSource)?, initialIndex: Int) {
        self.sourceViewController = sourceViewController
        self.initialIndex = initialIndex
    }

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        return ImageViewerPresentAnimator(
            sourceViewController: sourceViewController,
            initialIndex: initialIndex
        )
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ImageViewerDismissAnimator(sourceViewController: sourceViewController)
    }
}
