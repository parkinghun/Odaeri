//
//  FullscreenTransitionAnimator.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/22/26.
//

import UIKit
import AVFoundation

final class FullscreenTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let isPresenting: Bool
    private weak var sourceViewController: StreamingDetailViewController?
    private weak var destinationViewController: LandscapeVideoViewController?

    init(isPresenting: Bool, sourceViewController: StreamingDetailViewController? = nil, destinationViewController: LandscapeVideoViewController? = nil) {
        self.isPresenting = isPresenting
        self.sourceViewController = sourceViewController
        self.destinationViewController = destinationViewController
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if isPresenting {
            animatePresentation(using: transitionContext)
        } else {
            animateDismissal(using: transitionContext)
        }
    }

    private func animatePresentation(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toViewController = transitionContext.viewController(forKey: .to) as? LandscapeVideoViewController,
              let sourceVC = sourceViewController,
              let playerLayer = toViewController.playerLayer else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView
        let finalFrame = transitionContext.finalFrame(for: toViewController)

        toViewController.view.frame = finalFrame
        containerView.addSubview(toViewController.view)

        let sourceFrame = sourceVC.getSourceVideoFrame()
        toViewController.view.backgroundColor = .clear
        playerLayer.frame = sourceFrame

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0.3,
            options: [.curveEaseOut]
        ) {
            playerLayer.frame = toViewController.videoContainerView.bounds
            toViewController.view.backgroundColor = .black
        } completion: { finished in
            transitionContext.completeTransition(finished)
        }
    }

    private func animateDismissal(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromViewController = transitionContext.viewController(forKey: .from) as? LandscapeVideoViewController,
              let sourceVC = sourceViewController,
              let playerLayer = fromViewController.playerLayer else {
            transitionContext.completeTransition(false)
            return
        }

        let sourceFrame = sourceVC.getSourceVideoFrame()

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0.3,
            options: [.curveEaseIn]
        ) {
            playerLayer.frame = sourceFrame
            fromViewController.view.backgroundColor = .clear
        } completion: { finished in
            transitionContext.completeTransition(finished)
        }
    }
}
