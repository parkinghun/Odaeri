//
//  StreamingDetailViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/19/26.
//

import UIKit
import AVFoundation
import AVKit
import Combine
import SnapKit

final class StreamingDetailViewController: BaseViewController<StreamingDetailViewModel> {
    private let video: VideoEntity
    private let playerManager: StreamingPlayerManager
    private weak var pipController: AVPictureInPictureController?

    weak var coordinator: StreamingCoordinator?

    private let videoContainerView = VideoContainerView()
    private let controlOverlayView = VideoControlOverlayView()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = AppColor.gray0
        return scrollView
    }()

    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        return stack
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.title1
        label.textColor = AppColor.gray100
        label.numberOfLines = 0
        return label
    }()

    private let interactionBar = VideoInteractionBar()

    private let expandableDescription = ExpandableDescriptionView()

    private let subtitleTableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = AppColor.gray0
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.showsVerticalScrollIndicator = true
        tableView.register(SubtitleCell.self, forCellReuseIdentifier: SubtitleCell.reuseIdentifier)
        return tableView
    }()

    private let returnToCurrentButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("현재 자막으로", for: .normal)
        button.titleLabel?.font = AppFont.body3
        button.backgroundColor = AppColor.blackSprout
        button.setTitleColor(AppColor.gray0, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)
        button.isHidden = true
        return button
    }()

    private let manualScrollSubject = PassthroughSubject<Void, Never>()
    private let subtitleCellTappedSubject = PassthroughSubject<Int, Never>()
    private var subtitles: [SubtitleItem] = []
    private var currentHighlightedIndex: Int?

    private let fastForwardIndicatorLabel: UILabel = {
        let label = UILabel()
        label.text = "2배속으로 재생 중"
        label.font = AppFont.body2
        label.textColor = AppColor.gray0
        label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.isHidden = true
        return label
    }()

    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        button.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        button.tintColor = AppColor.gray0
        button.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        button.isHidden = true
        return button
    }()

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)

    init(video: VideoEntity, viewModel: StreamingDetailViewModel, playerManager: StreamingPlayerManager) {
        self.video = video
        self.playerManager = playerManager
        super.init(viewModel: viewModel)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGestures()
        setupCallbacks()
        setupTableView()
        setupNotifications()
        viewDidLoadSubject.send(())
        hapticGenerator.prepare()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoContainerView.playerLayer?.frame = videoContainerView.bounds
        returnToCurrentButton.layer.cornerRadius = returnToCurrentButton.frame.height / 2
    }

    override func setupUI() {
        super.setupUI()

        view.backgroundColor = AppColor.gray0

        view.addSubview(videoContainerView)
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(interactionBar)
        contentStackView.addArrangedSubview(expandableDescription)
        contentStackView.addArrangedSubview(subtitleTableView)

        view.addSubview(returnToCurrentButton)

        interactionBar.snp.makeConstraints { make in
            make.height.equalTo(40)
        }

        let player = playerManager.getPlayer()
        let layer = AVPlayerLayer(player: player)
        videoContainerView.attachPlayerLayer(layer)

        if pipController == nil {
            playerManager.setupPictureInPicture(with: layer)
            pipController = playerManager.getPIPController()
            pipController?.delegate = self
        }

        videoContainerView.addSubview(controlOverlayView)
        videoContainerView.addSubview(fastForwardIndicatorLabel)
        videoContainerView.addSubview(backButton)

        videoContainerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(videoContainerView.snp.width).multipliedBy(9.0 / 16.0)
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(videoContainerView.snp.bottom)
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
            make.width.equalTo(scrollView.snp.width).offset(-32)
        }

        controlOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        fastForwardIndicatorLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.centerX.equalToSuperview()
            make.height.equalTo(40)
            make.width.greaterThanOrEqualTo(150)
        }

        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.width.height.equalTo(40)
        }

        subtitleTableView.snp.makeConstraints { make in
            make.height.equalTo(300)
        }

        returnToCurrentButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.height.equalTo(36)
        }
    }

    private func setupTableView() {
        subtitleTableView.delegate = self
        subtitleTableView.dataSource = self
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func handleAppDidEnterBackground() {
        startPictureInPictureIfPossible()
    }

    @objc private func handleAppWillEnterForeground() {
    }

    private func startPictureInPictureIfPossible() {
        guard let pipController = pipController,
              !pipController.isPictureInPictureActive else {
            return
        }

        let player = playerManager.getPlayer()
        guard player.rate > 0 else {
            return
        }

        if pipController.isPictureInPicturePossible {
            pipController.startPictureInPicture()
        }
    }

    private func setupGestures() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        view.addGestureRecognizer(longPress)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        videoContainerView.addGestureRecognizer(panGesture)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: view)
        let isRightSide = location.x > view.bounds.width / 2

        guard isRightSide else { return }

        switch gesture.state {
        case .began:
            playerManager.startFastForward()
            fastForwardIndicatorLabel.isHidden = false
            hapticGenerator.impactOccurred()
        case .ended, .cancelled:
            playerManager.stopFastForward()
            fastForwardIndicatorLabel.isHidden = true
        default:
            break
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: videoContainerView)
        let velocity = gesture.velocity(in: videoContainerView)

        switch gesture.state {
        case .changed:
            break
        case .ended:
            let threshold: CGFloat = 100

            if translation.y < -threshold || velocity.y < -1000 {
                enterFullscreen()
            } else if translation.y > threshold || velocity.y > 1000 {
                handleBackNavigation()
            }
        default:
            break
        }
    }

    private func handleBackNavigation() {
        startPictureInPictureIfPossible()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }

    private func seekRelative(seconds: Double) {
        let player = playerManager.getPlayer()
        let currentTime = player.currentTime()
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: seconds, preferredTimescale: 600))

        guard let duration = player.currentItem?.duration else { return }

        let clampedTime: CMTime
        if newTime < .zero {
            clampedTime = .zero
        } else if newTime > duration {
            clampedTime = duration
        } else {
            clampedTime = newTime
        }

        playerManager.seek(to: clampedTime)
    }

    private func setupCallbacks() {
        viewModel.onPlayPauseTriggered = { [weak self] in
            guard let self = self else { return }
            let player = self.playerManager.getPlayer()

            if player.rate > 0 && player.error == nil {
                self.playerManager.pause()
            } else {
                self.playerManager.play()
            }
        }

        viewModel.onSeekRequested = { [weak self] time in
            guard let self = self else { return }
            self.playerManager.seek(to: time) { [weak self] in
                self?.playerManager.play()
            }
        }
    }

    override func bind() {
        super.bind()

        backButton.tapPublisher()
            .sink { [weak self] in
                self?.handleBackNavigation()
            }
            .store(in: &cancellables)

        controlOverlayView.onVisibilityChanged = { [weak self] isVisible in
            self?.backButton.isHidden = !isVisible
        }

        controlOverlayView.centerPlayPauseTappedPublisher
            .sink { [weak self] in
                self?.viewModel.onPlayPauseTriggered?()
                self?.controlOverlayView.resetAutoHideTimer()
            }
            .store(in: &cancellables)

        controlOverlayView.seekBackwardTappedPublisher
            .sink { [weak self] in
                self?.seekRelative(seconds: -10)
                self?.controlOverlayView.resetAutoHideTimer()
            }
            .store(in: &cancellables)

        controlOverlayView.seekForwardTappedPublisher
            .sink { [weak self] in
                self?.seekRelative(seconds: 10)
                self?.controlOverlayView.resetAutoHideTimer()
            }
            .store(in: &cancellables)

        let controlView = controlOverlayView.getControlView()

        let input = StreamingDetailViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            playPauseTapped: controlView.playPauseTappedPublisher,
            seekToProgress: controlView.seekToProgressPublisher,
            settingsTapped: controlView.settingsTappedPublisher,
            currentTime: playerManager.currentTimePublisher,
            duration: playerManager.durationPublisher,
            isPlaying: playerManager.isPlayingPublisher,
            externalSubtitles: playerManager.subtitleManager.externalSubtitleDataPublisher,
            currentSubtitleIndex: playerManager.subtitleManager.currentSubtitleIndexPublisher,
            manualScrollDetected: manualScrollSubject.eraseToAnyPublisher(),
            returnToCurrentTapped: returnToCurrentButton.tapPublisher(),
            subtitleCellTapped: subtitleCellTappedSubject.eraseToAnyPublisher(),
            likeButtonTapped: interactionBar.likeButtonTappedPublisher,
            shareButtonTapped: interactionBar.shareButtonTappedPublisher,
            saveButtonTapped: interactionBar.saveButtonTappedPublisher,
            scriptButtonTapped: interactionBar.scriptButtonTappedPublisher,
            availableSubtitles: playerManager.subtitleManager.availableSubtitlesPublisher
        )

        let output = viewModel.transform(input: input)

        output.streamURL
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] url in
                self?.playerManager.loadVideo(url: url)
                self?.playerManager.play()
            }
            .store(in: &cancellables)

        output.currentTimeText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.controlOverlayView.getControlView().updateCurrentTimeText(text)
            }
            .store(in: &cancellables)

        output.durationText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.controlOverlayView.getControlView().updateDurationText(text)
            }
            .store(in: &cancellables)

        output.progress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.controlOverlayView.getControlView().updateProgress(progress)
            }
            .store(in: &cancellables)

        output.isPlayingState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPlaying in
                self?.controlOverlayView.getControlView().updatePlayPauseButton(isPlaying: isPlaying)
                self?.controlOverlayView.updateCenterPlayPauseButton(isPlaying: isPlaying)
            }
            .store(in: &cancellables)

        output.showSpeedSettings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] speeds in
                self?.showSpeedSettingsAlert(speeds: speeds)
            }
            .store(in: &cancellables)

        controlView.playPauseTappedPublisher
            .sink { [weak self] in
                self?.controlOverlayView.resetAutoHideTimer()
            }
            .store(in: &cancellables)

        controlView.seekToProgressPublisher
            .sink { [weak self] _ in
                self?.controlOverlayView.resetAutoHideTimer()
            }
            .store(in: &cancellables)

        controlView.settingsTappedPublisher
            .sink { [weak self] in
                self?.controlOverlayView.resetAutoHideTimer()
            }
            .store(in: &cancellables)

        controlView.subtitleTappedPublisher
            .sink { [weak self] in
                self?.showSubtitleSelectionAlert()
                self?.controlOverlayView.resetAutoHideTimer()
            }
            .store(in: &cancellables)

        controlView.fullscreenTappedPublisher
            .sink { [weak self] in
                self?.enterFullscreen()
            }
            .store(in: &cancellables)

        output.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                self?.showAlert(title: "오류", message: errorMessage)
            }
            .store(in: &cancellables)

        output.title
            .receive(on: DispatchQueue.main)
            .sink { [weak self] title in
                self?.titleLabel.text = title
            }
            .store(in: &cancellables)

        output.description
            .receive(on: DispatchQueue.main)
            .sink { [weak self] description in
                self?.expandableDescription.configure(text: description)
            }
            .store(in: &cancellables)

        Publishers.CombineLatest(output.isLiked, output.likeCount)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLiked, likeCount in
                self?.interactionBar.configure(isLiked: isLiked, likeCount: likeCount, animated: true)
            }
            .store(in: &cancellables)

        output.isSaved
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSaved in
                self?.interactionBar.updateSaveButton(isSaved: isSaved)
            }
            .store(in: &cancellables)

        output.showScriptMenu
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tracks in
                self?.showScriptSelectionAlert(tracks: tracks)
            }
            .store(in: &cancellables)

        output.showShareSheet
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                let payload = ShareCardPayload(
                    title: self.video.title,
                    thumbnailUrl: self.video.thumbnailUrl,
                    videoId: self.video.videoId
                )
                self.coordinator?.presentShareSheet(from: self, payload: payload)
            }
            .store(in: &cancellables)

        playerManager.subtitleManager.currentSubtitlePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currentSubtitle in
                let isActive = currentSubtitle?.source != .none
                self?.controlOverlayView.getControlView().updateSubtitleButton(isActive: isActive)
            }
            .store(in: &cancellables)

        output.subtitles
            .receive(on: DispatchQueue.main)
            .sink { [weak self] subtitles in
                guard let self = self else { return }
                self.subtitles = subtitles
                self.subtitleTableView.reloadData()
            }
            .store(in: &cancellables)

        output.indexPathsToReload
            .receive(on: DispatchQueue.main)
            .sink { [weak self] indexPaths in
                guard let self = self else { return }
                self.subtitleTableView.reloadRows(at: indexPaths, with: .none)
            }
            .store(in: &cancellables)

        output.scrollToIndex
            .receive(on: DispatchQueue.main)
            .sink { [weak self] index in
                guard let self = self else { return }
                self.currentHighlightedIndex = index
                let indexPath = IndexPath(row: index, section: 0)
                self.subtitleTableView.scrollToRow(at: indexPath, at: .middle, animated: true)
            }
            .store(in: &cancellables)

        playerManager.subtitleManager.currentSubtitleIndexPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] index in
                self?.currentHighlightedIndex = index
            }
            .store(in: &cancellables)

        output.showReturnButton
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldShow in
                self?.returnToCurrentButton.isHidden = !shouldShow
            }
            .store(in: &cancellables)

        output.streamEntity
            .receive(on: DispatchQueue.main)
            .sink { [weak self] streamEntity in
                guard let self = self else { return }
                self.playerManager.setVideoInfo(subtitles: streamEntity.subtitles)
            }
            .store(in: &cancellables)
    }

    private func showSpeedSettingsAlert(speeds: [Float]) {
        let alert = UIAlertController(title: "재생 속도", message: nil, preferredStyle: .actionSheet)

        for speed in speeds {
            let title = speed == 1.0 ? "일반 (1.0x)" : "\(speed)x"
            let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.playerManager.setPreferredRate(speed)
            }
            alert.addAction(action)
        }

        let cancel = UIAlertAction(title: "취소", style: .cancel)
        alert.addAction(cancel)

        present(alert, animated: true)
    }

    private func showSubtitleSelectionAlert() {
        let availableSubtitles = playerManager.subtitleManager.availableSubtitlesPublisher
        let currentSubtitle = playerManager.subtitleManager.currentSubtitlePublisher

        Publishers.CombineLatest(availableSubtitles, currentSubtitle)
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] subtitles, current in
                guard let self = self else { return }

                let alert = UIAlertController(title: "자막", message: nil, preferredStyle: .actionSheet)

                for subtitle in subtitles {
                    let isSelected = subtitle.id == current?.id
                    let title = isSelected ? "✓ \(subtitle.name)" : subtitle.name

                    let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                        self?.playerManager.subtitleManager.selectSubtitle(subtitle)
                    }
                    alert.addAction(action)
                }

                let cancel = UIAlertAction(title: "취소", style: .cancel)
                alert.addAction(cancel)

                self.present(alert, animated: true)
            }
            .store(in: &cancellables)
    }

    private func showScriptSelectionAlert(tracks: [SubtitleTrack]) {
        playerManager.subtitleManager.currentSubtitlePublisher
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] current in
                guard let self = self else { return }

                let alert = UIAlertController(title: "스크립트", message: nil, preferredStyle: .actionSheet)

                for track in tracks {
                    let isSelected = track.id == current?.id
                    let title = isSelected ? "✓ \(track.name)" : track.name

                    let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                        self?.playerManager.subtitleManager.selectSubtitle(track)
                    }
                    alert.addAction(action)
                }

                let cancel = UIAlertAction(title: "취소", style: .cancel)
                alert.addAction(cancel)

                self.present(alert, animated: true)
            }
            .store(in: &cancellables)
    }

    private func enterFullscreen() {
        guard let playerLayer = videoContainerView.detachPlayerLayer() else { return }

        let landscapeVC = LandscapeVideoViewController(viewModel: viewModel)
        landscapeVC.delegate = self
        landscapeVC.modalPresentationStyle = .custom
        landscapeVC.transitioningDelegate = self

        landscapeVC.loadViewIfNeeded()
        landscapeVC.attachPlayerLayer(playerLayer)
        landscapeVC.setPlayerManager(playerManager)

        let landscapeControlView = landscapeVC.getControlOverlayView().getControlView()
        bindControlViewToViewModel(landscapeControlView)
        bindViewModelOutputToControlView(landscapeControlView)

        present(landscapeVC, animated: true)
    }

    private func exitFullscreen(playerLayer: AVPlayerLayer) {
        videoContainerView.attachPlayerLayer(playerLayer)

        let controlView = controlOverlayView.getControlView()
        bindControlViewToViewModel(controlView)
    }

    private func bindControlViewToViewModel(_ controlView: PlayerControlView) {
        controlView.playPauseTappedPublisher
            .sink { [weak self] in
                self?.viewModel.onPlayPauseTriggered?()
            }
            .store(in: &cancellables)

        controlView.settingsTappedPublisher
            .sink { [weak self] in
                guard let self = self else { return }
                let speeds: [Float] = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                self.showSpeedSettingsAlert(speeds: speeds)
            }
            .store(in: &cancellables)

        controlView.subtitleTappedPublisher
            .sink { [weak self] in
                self?.showSubtitleSelectionAlert()
            }
            .store(in: &cancellables)
    }

    private func bindViewModelOutputToControlView(_ controlView: PlayerControlView) {
        let input = StreamingDetailViewModel.Input(
            viewDidLoad: Empty().eraseToAnyPublisher(),
            playPauseTapped: Empty().eraseToAnyPublisher(),
            seekToProgress: Empty().eraseToAnyPublisher(),
            settingsTapped: Empty().eraseToAnyPublisher(),
            currentTime: playerManager.currentTimePublisher,
            duration: playerManager.durationPublisher,
            isPlaying: playerManager.isPlayingPublisher,
            externalSubtitles: playerManager.subtitleManager.externalSubtitleDataPublisher,
            currentSubtitleIndex: playerManager.subtitleManager.currentSubtitleIndexPublisher,
            manualScrollDetected: Empty().eraseToAnyPublisher(),
            returnToCurrentTapped: Empty().eraseToAnyPublisher(),
            subtitleCellTapped: Empty().eraseToAnyPublisher(),
            likeButtonTapped: Empty().eraseToAnyPublisher(),
            shareButtonTapped: Empty().eraseToAnyPublisher(),
            saveButtonTapped: Empty().eraseToAnyPublisher(),
            scriptButtonTapped: Empty().eraseToAnyPublisher(),
            availableSubtitles: playerManager.subtitleManager.availableSubtitlesPublisher
        )

        let output = viewModel.transform(input: input)

        output.currentTimeText
            .receive(on: DispatchQueue.main)
            .sink { text in
                controlView.updateCurrentTimeText(text)
            }
            .store(in: &cancellables)

        output.durationText
            .receive(on: DispatchQueue.main)
            .sink { text in
                controlView.updateDurationText(text)
            }
            .store(in: &cancellables)

        output.progress
            .receive(on: DispatchQueue.main)
            .sink { progress in
                controlView.updateProgress(progress)
            }
            .store(in: &cancellables)

        output.isPlayingState
            .receive(on: DispatchQueue.main)
            .sink { isPlaying in
                controlView.updatePlayPauseButton(isPlaying: isPlaying)
            }
            .store(in: &cancellables)

        playerManager.subtitleManager.currentSubtitlePublisher
            .receive(on: DispatchQueue.main)
            .sink { currentSubtitle in
                let isActive = currentSubtitle?.source != .none
                controlView.updateSubtitleButton(isActive: isActive)
            }
            .store(in: &cancellables)
    }
}

extension StreamingDetailViewController: LandscapeVideoViewControllerDelegate {
    func landscapeVideoViewControllerDidFinish(_ viewController: LandscapeVideoViewController, playerLayer: AVPlayerLayer) {
        exitFullscreen(playerLayer: playerLayer)
    }

    func getSourceVideoFrame() -> CGRect {
        return videoContainerView.convert(videoContainerView.bounds, to: nil)
    }
}

extension StreamingDetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return subtitles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: SubtitleCell.reuseIdentifier,
            for: indexPath
        ) as? SubtitleCell else {
            return UITableViewCell()
        }

        let subtitle = subtitles[indexPath.row]
        let isHighlighted = (indexPath.row == currentHighlightedIndex)
        cell.configure(with: subtitle, isHighlighted: isHighlighted)

        return cell
    }
}

extension StreamingDetailViewController: UITableViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        manualScrollSubject.send(())
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        subtitleCellTappedSubject.send(indexPath.row)
    }
}

extension StreamingDetailViewController: UIViewControllerTransitioningDelegate {
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        guard let landscapeVC = presented as? LandscapeVideoViewController else { return nil }
        return FullscreenTransitionAnimator(
            isPresenting: true,
            sourceViewController: self,
            destinationViewController: landscapeVC
        )
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FullscreenTransitionAnimator(
            isPresenting: false,
            sourceViewController: self
        )
    }
}

extension StreamingDetailViewController {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
            let translation = panGesture.translation(in: videoContainerView)
            return abs(translation.y) > abs(translation.x)
        }
        return true
    }
}

extension StreamingDetailViewController: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    }

    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        videoContainerView.isHidden = true
        coordinator?.retainPIPSession(playerManager: playerManager, viewController: self, video: video)
    }

    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        videoContainerView.isHidden = false
        coordinator?.releasePIPSession()
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        coordinator?.restorePIPViewController { [weak self] success in
            guard let self = self else {
                completionHandler(false)
                return
            }

            DispatchQueue.main.async {
                self.videoContainerView.isHidden = false

                if let playerLayer = self.videoContainerView.playerLayer {
                    playerLayer.frame = self.videoContainerView.bounds
                }

                completionHandler(success)
            }
        }
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        showAlert(title: "PIP 오류", message: "Picture in Picture를 시작할 수 없습니다.\n\(error.localizedDescription)")
    }
}
