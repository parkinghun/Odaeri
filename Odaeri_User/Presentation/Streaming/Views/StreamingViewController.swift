//
//  StreamingViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/12/26.
//

import UIKit
import Combine
import SnapKit

final class StreamingViewController: BaseViewController<StreamingViewModel> {
    enum Section {
        case main
    }

    override var navigationBarHidden: Bool {
        return true
    }

    deinit {
        scrollSettleTimer?.invalidate()
    }

    private var videoDisplays: [StreamingVideoDisplay] = []
    private var expandedVideoIds = Set<String>()
    private var currentIndex: Int = 0
    private var lastTabBarInset: CGFloat = 0

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let indexChangedSubject = PassthroughSubject<Int, Never>()
    private let qualitySelectedSubject = PassthroughSubject<StreamingViewModel.QualitySelection, Never>()
    private let likeToggledSubject = PassthroughSubject<StreamingViewModel.LikeToggleEvent, Never>()
    private var collectionViewBottomConstraint: Constraint?
    private let scrollVelocitySubject = PassthroughSubject<StreamingViewModel.ScrollVelocityEvent, Never>()
    private var scrollSettleTimer: Timer?
    private var pendingLoadIndex: Int?

    private var dataSource: UICollectionViewDiffableDataSource<Section, StreamingVideoDisplay>!

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = AppColor.gray100
        collectionView.decelerationRate = .fast
        collectionView.register(StreamingVideoCell.self, forCellWithReuseIdentifier: StreamingVideoCell.reuseIdentifier)
        collectionView.delegate = self
        return collectionView
    }()

    override func setupUI() {
        super.setupUI()
        view.backgroundColor = AppColor.gray100
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            collectionViewBottomConstraint = make.bottom.equalToSuperview().constraint
        }
        setupDataSource()
    }

    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, StreamingVideoDisplay>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, display in
            guard let self = self,
                  let cell = collectionView.dequeueReusableCell(
                      withReuseIdentifier: StreamingVideoCell.reuseIdentifier,
                      for: indexPath
                  ) as? StreamingVideoCell else {
                return UICollectionViewCell()
            }

            cell.cancellables.removeAll()
            let player = self.viewModel.player(for: indexPath.item)
            cell.configure(display: display, player: player)
            cell.overlayView.setDescriptionExpanded(self.expandedVideoIds.contains(display.videoId))
            cell.likeTapPublisher
                .sink { [weak self] event in
                    self?.likeToggledSubject.send(
                        .init(videoId: event.videoId, newState: event.newState)
                    )
                }
                .store(in: &cell.cancellables)
            cell.overlayView.onMoreTapped = { [weak self] in
                self?.toggleDescription(for: display, at: indexPath)
            }
            return cell
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCollectionViewInsetsIfNeeded()
    }

    override func bind() {
        let input = StreamingViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            didChangeIndex: indexChangedSubject.eraseToAnyPublisher(),
            didEnterBackground: NotificationCenter.default.publisher(
                for: UIApplication.didEnterBackgroundNotification
            ).map { _ in }.eraseToAnyPublisher(),
            didBecomeActive: NotificationCenter.default.publisher(
                for: UIApplication.didBecomeActiveNotification
            ).map { _ in }.eraseToAnyPublisher(),
            qualitySelected: qualitySelectedSubject.eraseToAnyPublisher(),
            likeToggled: likeToggledSubject.eraseToAnyPublisher(),
            scrollVelocity: scrollVelocitySubject.eraseToAnyPublisher()
        )

        let output = viewModel.transform(input: input)

        output.videos
            .sink { [weak self] displays in
                guard let self = self else { return }
                self.videoDisplays = displays

                var snapshot = NSDiffableDataSourceSnapshot<Section, StreamingVideoDisplay>()
                snapshot.appendSections([.main])
                snapshot.appendItems(displays)
                self.dataSource.apply(snapshot, animatingDifferences: false)

                if !displays.isEmpty && self.currentIndex == 0 {
                    self.scrollToIndex(0, animated: false)
                    self.indexChangedSubject.send(0)
                }
            }
            .store(in: &cancellables)

        output.likeUpdated
            .sink { [weak self] updatedDisplay in
                guard let self = self else { return }
                guard let index = self.videoDisplays.firstIndex(where: { $0.videoId == updatedDisplay.videoId }) else {
                    return
                }

                self.videoDisplays[index] = updatedDisplay

                let indexPath = IndexPath(item: index, section: 0)
                if let cell = self.collectionView.cellForItem(at: indexPath) as? StreamingVideoCell {
                    cell.updateLikeDisplay(
                        isLiked: updatedDisplay.isLiked,
                        likeCountText: updatedDisplay.likeCountText
                    )
                }
            }
            .store(in: &cancellables)

        output.currentIndex
            .sink { [weak self] index in
                self?.currentIndex = index
                self?.playVideoIfVisible(index: index)
            }
            .store(in: &cancellables)

        output.error
            .sink { [weak self] message in
                self?.showAlert(title: "스트리밍 오류", message: message)
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
    }

    private func scrollToIndex(_ index: Int, animated: Bool) {
        guard videoDisplays.indices.contains(index) else { return }
        let indexPath = IndexPath(item: index, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: animated)
    }

    private func playVideoIfVisible(index: Int) {
        guard videoDisplays.indices.contains(index) else { return }
        guard let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? StreamingVideoCell else {
            return
        }
        let player = viewModel.player(for: index)
        cell.configure(display: videoDisplays[index], player: player)
        player.play()
    }

    private func toggleDescription(for display: StreamingVideoDisplay, at indexPath: IndexPath) {
        if expandedVideoIds.contains(display.videoId) {
            expandedVideoIds.remove(display.videoId)
        } else {
            expandedVideoIds.insert(display.videoId)
        }
        collectionView.reloadItems(at: [indexPath])
    }

    private func updateCollectionViewInsetsIfNeeded() {
        let tabBarInset = currentTabBarInset()
        guard tabBarInset != lastTabBarInset else { return }
        lastTabBarInset = tabBarInset
        collectionViewBottomConstraint?.update(offset: -tabBarInset)
    }

    private func currentTabBarInset() -> CGFloat {
        if let tabBarController = tabBarController as? CustomTabBarController {
            let tabBar = tabBarController.view.subviews.first { $0 is CustomTabBar }
            if let tabBar {
                return tabBar.frame.height
            }
        }
        return 60 + view.safeAreaInsets.bottom
    }
}

extension StreamingViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return collectionView.bounds.size
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let velocity = scrollView.panGestureRecognizer.velocity(in: scrollView).y
        let pageHeight = scrollView.bounds.height
        guard pageHeight > 0 else { return }
        let index = Int(round(scrollView.contentOffset.y / pageHeight))

        scrollVelocitySubject.send(.init(velocity: velocity, index: index))
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageHeight = scrollView.bounds.height
        guard pageHeight > 0 else { return }
        let index = Int(round(scrollView.contentOffset.y / pageHeight))

        scrollSettleTimer?.invalidate()

        scrollSettleTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            self?.indexChangedSubject.send(index)
        }

        scrollVelocitySubject.send(.init(velocity: 0, index: index))
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        let player = viewModel.player(for: indexPath.item)
        player.pause()
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard let cell = cell as? StreamingVideoCell else { return }
        let display = videoDisplays[indexPath.item]
        let player = viewModel.player(for: indexPath.item)
        cell.configure(display: display, player: player)
        cell.overlayView.setDescriptionExpanded(expandedVideoIds.contains(display.videoId))
        if indexPath.item == currentIndex {
            player.play()
        }
    }
}
