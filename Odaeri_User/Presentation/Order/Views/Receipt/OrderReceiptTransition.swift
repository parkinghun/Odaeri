//
//  OrderReceiptTransition.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/10/26.
//

import UIKit

final class OrderReceiptTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        return OrderReceiptPresentationController(presentedViewController: presented, presenting: presenting)
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController)
    -> UIViewControllerAnimatedTransitioning? {
        return OrderReceiptAnimator(isPresenting: true)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return OrderReceiptAnimator(isPresenting: false)
    }
}

final class OrderReceiptPresentationController: UIPresentationController {
    private let dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.alpha = 0
        return view
    }()

    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDimmingTap))
        dimmingView.addGestureRecognizer(tapGesture)
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView else { return .zero }
        let containerBounds = containerView.bounds
        let preferredHeight = presentedViewController.preferredContentSize.height
        let sheetHeight = preferredHeight > 0 ? min(preferredHeight, containerBounds.height * 0.75) : containerBounds.height * 0.75
        let originY = (containerBounds.height - sheetHeight) / 2
        return CGRect(
            x: 0,
            y: originY,
            width: containerBounds.width,
            height: sheetHeight
        )
    }

    override func presentationTransitionWillBegin() {
        guard let containerView else { return }
        dimmingView.frame = containerView.bounds
        containerView.addSubview(dimmingView)

        if let coordinator = presentedViewController.transitionCoordinator {
            coordinator.animate { _ in
                self.dimmingView.alpha = 1
            }
        } else {
            dimmingView.alpha = 1
        }
    }

    override func dismissalTransitionWillBegin() {
        if let coordinator = presentedViewController.transitionCoordinator {
            coordinator.animate { _ in
                self.dimmingView.alpha = 0
            }
        } else {
            dimmingView.alpha = 0
        }
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            dimmingView.removeFromSuperview()
        }
    }

    @objc private func handleDimmingTap() {
        presentedViewController.dismiss(animated: true)
    }
}

final class OrderReceiptAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let isPresenting: Bool

    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let presentedView = transitionContext.view(forKey: isPresenting ? .to : .from) else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView
        let duration = transitionDuration(using: transitionContext)

        if isPresenting {
            containerView.addSubview(presentedView)
        }

        let finalFrame = transitionContext.finalFrame(for: transitionContext.viewController(forKey: .to) ?? UIViewController())
        let startFrame = CGRect(
            x: finalFrame.origin.x,
            y: containerView.bounds.height,
            width: finalFrame.width,
            height: finalFrame.height
        )

        let fromFrame = isPresenting ? startFrame : finalFrame
        let toFrame = isPresenting ? finalFrame : startFrame
        presentedView.frame = fromFrame

        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut]) {
            presentedView.frame = toFrame
        } completion: { finished in
            transitionContext.completeTransition(finished)
        }
    }
}
