//
//  ImageViewerViewController.swift
//  Odaeri
//
//  Created by 박성훈 on 01/21/26.
//

import UIKit

final class ImageViewerViewController: UIViewController {

    private let imageUrls: [String]
    private let initialIndex: Int
    private weak var transitionSource: ImageViewerTransitionSource?

    var currentIndex: Int {
        let width = collectionView.bounds.width
        guard width > 0 else { return initialIndex }
        let offset = collectionView.contentOffset.x
        return Int(round(offset / width))
    }

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .black
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.delegate = self
        cv.dataSource = self
        cv.register(ImageViewerCell.self, forCellWithReuseIdentifier: ImageViewerCell.identifier)
        return cv
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.numberOfPages = imageUrls.count
        pc.currentPage = initialIndex
        pc.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.5)
        pc.currentPageIndicatorTintColor = .white
        pc.isUserInteractionEnabled = false
        return pc
    }()

    private var isUIVisible = true
    private var panGesture: UIPanGestureRecognizer?
    private var originalCenter: CGPoint = .zero
    private var customTransitionDelegate: ImageViewerTransitioningDelegate?
    private var hasSetInitialOffset = false

    init(
        imageUrls: [String],
        initialIndex: Int,
        transitionSource: ImageViewerTransitionSource? = nil
    ) {
        self.imageUrls = imageUrls
        self.initialIndex = initialIndex
        self.transitionSource = transitionSource
        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .fullScreen
        modalPresentationCapturesStatusBarAppearance = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTransitionDelegate(_ delegate: ImageViewerTransitioningDelegate) {
        customTransitionDelegate = delegate
        transitioningDelegate = delegate
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard !hasSetInitialOffset else { return }

        let width = collectionView.bounds.width
        guard width > 0 else { return }

        let offset = CGFloat(initialIndex) * width
        collectionView.setContentOffset(CGPoint(x: offset, y: 0), animated: false)
        hasSetInitialOffset = true
    }

    override var prefersStatusBarHidden: Bool {
        return !isUIVisible
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }

    private func setupUI() {
        view.backgroundColor = .black

        view.addSubview(collectionView)
        view.addSubview(closeButton)
        view.addSubview(pageControl)

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        pageControl.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40),

            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        view.addGestureRecognizer(pan)
        panGesture = pan
    }

    @objc private func handleTap() {
        toggleUI()
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)

        switch gesture.state {
        case .began:
            originalCenter = view.center

        case .changed:
            let progress = abs(translation.y) / view.bounds.height
            let scale = max(0.8, 1.0 - progress * 0.2)
            let alpha = max(0.3, 1.0 - progress * 0.7)

            view.center = CGPoint(x: originalCenter.x, y: originalCenter.y + translation.y)
            view.transform = CGAffineTransform(scaleX: scale, y: scale)
            view.backgroundColor = UIColor.black.withAlphaComponent(alpha)

        case .ended, .cancelled:
            let threshold: CGFloat = 100
            let shouldDismiss = abs(translation.y) > threshold || abs(velocity.y) > 1000

            if shouldDismiss {
                dismiss(animated: true)
            } else {
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
                    self.view.center = self.originalCenter
                    self.view.transform = .identity
                    self.view.backgroundColor = .black
                }
            }

        default:
            break
        }
    }

    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }

    private func toggleUI() {
        isUIVisible.toggle()

        UIView.animate(withDuration: 0.3) {
            self.closeButton.alpha = self.isUIVisible ? 1.0 : 0.0
            self.pageControl.alpha = self.isUIVisible ? 1.0 : 0.0
        }

        UIView.animate(withDuration: 0.2) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
}

// MARK: - UICollectionViewDataSource

extension ImageViewerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageUrls.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ImageViewerCell.identifier,
            for: indexPath
        ) as? ImageViewerCell else {
            return UICollectionViewCell()
        }

        cell.zoomDelegate = self

        let imageUrl = imageUrls[indexPath.item]
        cell.configure(with: imageUrl)

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension ImageViewerViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = scrollView.bounds.width
        guard width > 0 else { return }

        let page = Int(round(scrollView.contentOffset.x / width))
        if page != pageControl.currentPage {
            pageControl.currentPage = page
            manageMemoryForCurrentPage(page)
        }
    }

    private func manageMemoryForCurrentPage(_ currentPage: Int) {
        let prefetchRange = -1...1

        for (index, imageUrl) in imageUrls.enumerated() {
            let isInPrefetchRange = prefetchRange.contains(index - currentPage)

            if !isInPrefetchRange {
                ImageCacheManager.shared.removeImageFromMemory(for: imageUrl)
            }
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension ImageViewerViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return collectionView.bounds.size
    }
}

// MARK: - ImageViewerTransitionSource

extension ImageViewerViewController: ImageViewerTransitionSource {
    func frameForImage(at index: Int) -> CGRect? {
        guard let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? ImageViewerCell else {
            return nil
        }

        return cell.imageViewFrame
    }

    func imageView(at index: Int) -> UIImageView? {
        guard let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? ImageViewerCell else {
            return nil
        }

        return cell.imageView
    }
}

// MARK: - ZoomableImageViewDelegate

extension ImageViewerViewController: ZoomableImageViewDelegate {
    func zoomableImageViewDidChangeZoom(_ zoomableImageView: ZoomableImageView) {
        let zoomScale = zoomableImageView.zoomScale
        let contentOffset = zoomableImageView.contentOffset
        let contentSize = zoomableImageView.contentSize
        let bounds = zoomableImageView.bounds

        if zoomScale > 1.0 {
            let isAtLeftEdge = contentOffset.x <= 0
            let isAtRightEdge = contentOffset.x >= contentSize.width - bounds.width

            collectionView.isScrollEnabled = isAtLeftEdge || isAtRightEdge
        } else {
            collectionView.isScrollEnabled = true
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension ImageViewerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == panGesture else { return true }

        let visibleCells = collectionView.visibleCells
        guard let cell = visibleCells.first as? ImageViewerCell else { return true }

        return cell.zoomableImageView.zoomScale == 1.0
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return false
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if gestureRecognizer is UITapGestureRecognizer,
           otherGestureRecognizer is UITapGestureRecognizer {
            let tap1 = gestureRecognizer as! UITapGestureRecognizer
            let tap2 = otherGestureRecognizer as! UITapGestureRecognizer

            if tap1.numberOfTapsRequired == 1 && tap2.numberOfTapsRequired == 2 {
                return true
            }
        }

        return false
    }
}
