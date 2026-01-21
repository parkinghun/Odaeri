//
//  ImageViewerPresentable.swift
//  Odaeri
//
//  Created by 박성훈 on 01/21/26.
//

import UIKit

protocol ImageViewerPresentable: UIViewController {
    func presentImageViewer(
        imageUrls: [String],
        initialIndex: Int,
        transitionSource: ImageViewerTransitionSource?
    )
}

extension ImageViewerPresentable {
    func presentImageViewer(
        imageUrls: [String],
        initialIndex: Int,
        transitionSource: ImageViewerTransitionSource? = nil
    ) {
        let imageViewerVC = ImageViewerViewController(
            imageUrls: imageUrls,
            initialIndex: initialIndex,
            transitionSource: transitionSource
        )

        let sourceVC = transitionSource as? (UIViewController & ImageViewerTransitionSource)

        let transitionDelegate = ImageViewerTransitioningDelegate(
            sourceViewController: sourceVC,
            initialIndex: initialIndex
        )

        imageViewerVC.setTransitionDelegate(transitionDelegate)

        present(imageViewerVC, animated: true)
    }
}
