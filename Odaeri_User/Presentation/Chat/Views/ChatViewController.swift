//
//  ChatViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/10/26.
//

import UIKit
import Combine
import SnapKit
import QuartzCore

final class ChatViewController: BaseViewController<ChatViewModel>, ImageViewerPresentable {
    override var navigationBarHidden: Bool { false }

    private lazy var collectionView: UICollectionView = {
        let layout = ChatCollectionViewLayout()
        layout.layoutDataProvider = { [weak self] indexPath in
            self?.getLayoutData(for: indexPath)
        }
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        return cv
    }()

    private let chatInputView = ChatInputView()
    private let newMessageToastView = UIView()
    private let toastLabel = UILabel()

    private var dataSource: UICollectionViewDiffableDataSource<Section, ChatItem>!
    private var chatItems: [ChatItem] = []
    private var lastItemIds: [String] = []
    private var hasAppliedInitialSnapshot = false
    private var isLoadingMore = false
    private var pendingPaginationCount: Int?
    private var lastSentMessageId: String?
    private var didInitialScroll = false
    private var keyboardHeight: CGFloat = 0
    private var previousScrollViewHeight: CGFloat = 0

    private enum Section: Hashable {
        case main
    }

    private enum Layout {
        static let paginationThreshold: CGFloat = ChatConstants.Pagination.threshold
    }
    
    override func setupUI() {
        super.setupUI()
        view.backgroundColor = AppColor.gray0
        navigationItem.title = viewModel.title ?? "채팅"

        setupCollectionView()
        setupInputView()
        setupToastView()
        setupConstraints()
        configureDataSource()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        ChatSocketService.shared.connect(to: viewModel.roomId)
        ChatRoomContextManager.shared.enter(roomId: viewModel.roomId)

        RealmChatRepository.shared.markAllMessagesAsRead(roomId: viewModel.roomId)
            .sink { _ in }
            .store(in: &cancellables)

        setupKeyboardObservers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ChatSocketService.shared.disconnect()
        ChatRoomContextManager.shared.leave(roomId: viewModel.roomId)
        removeKeyboardObservers()
    }
    
    override func bind() {
        super.bind()
        
        let viewDidLoadSubject = PassthroughSubject<Void, Never>()
        let sendMessageSubject = PassthroughSubject<ChatViewModel.SendMessagePayload, Never>()
        
        let input = ChatViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            sendMessage: sendMessageSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)
        
        output.chatItems
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self = self else { return }
                self.handleNewChatItems(items)
            }
            .store(in: &cancellables)

        output.isLoadingMore
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.isLoadingMore = isLoading
            }
            .store(in: &cancellables)

        chatInputView.onSendMessage = { [weak self, weak sendMessageSubject] message, attachments in
            guard let self = self else { return }
            let tempId = UUID().uuidString
            self.lastSentMessageId = tempId

            let payload = ChatViewModel.SendMessagePayload(content: message, attachments: attachments)
            sendMessageSubject?.send(payload)
        }
        
        viewDidLoadSubject.send(())
    }
    
    private func setupCollectionView() {
        collectionView.backgroundColor = AppColor.gray0
        collectionView.keyboardDismissMode = .interactive
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.isHidden = true

        setKeyboardDismissMode(.interactive, for: collectionView)

        collectionView.register(ChatMessageCell.self, forCellWithReuseIdentifier: ChatMessageCell.reuseIdentifier)
        collectionView.register(ChatDateSeparatorCell.self, forCellWithReuseIdentifier: ChatDateSeparatorCell.reuseIdentifier)

        collectionView.delegate = self

        view.addSubview(collectionView)
        view.addSubview(chatInputView)
    }
    
    private func setupInputView() {
        chatInputView.parentViewController = self
    }

    private func setupToastView() {
        newMessageToastView.backgroundColor = AppColor.blackSprout
        newMessageToastView.layer.cornerRadius = 16
        newMessageToastView.clipsToBounds = true
        newMessageToastView.alpha = 0
        newMessageToastView.isUserInteractionEnabled = true

        toastLabel.text = "새 메시지"
        toastLabel.font = AppFont.caption1
        toastLabel.textColor = AppColor.gray0
        toastLabel.textAlignment = .center

        newMessageToastView.addSubview(toastLabel)
        view.addSubview(newMessageToastView)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toastTapped))
        newMessageToastView.addGestureRecognizer(tapGesture)
    }

    @objc private func toastTapped() {
        hideToast()
        scrollToBottom(animated: true)
    }

    private func showToast() {
        UIView.animate(withDuration: 0.3) {
            self.newMessageToastView.alpha = 1
        }
    }

    private func hideToast() {
        UIView.animate(withDuration: 0.3) {
            self.newMessageToastView.alpha = 0
        }
    }

    private func setupConstraints() {
        collectionView.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.equalTo(chatInputView.snp.top)
        }

        chatInputView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.keyboardLayoutGuide.snp.top)
        }

        toastLabel.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
        }

        newMessageToastView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(chatInputView.snp.top).offset(-16)
        }
    }
    
    
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, ChatItem>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, item in
            switch item {
            case .message:
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ChatMessageCell.reuseIdentifier,
                    for: indexPath
                ) as? ChatMessageCell else {
                    return UICollectionViewCell()
                }
                cell.delegate = self
                return cell

            case .dateSeparator:
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ChatDateSeparatorCell.reuseIdentifier,
                    for: indexPath
                ) as? ChatDateSeparatorCell else {
                    return UICollectionViewCell()
                }
                return cell
            }
        }
    }

    private func getLayoutData(for indexPath: IndexPath) -> ChatCellLayoutData? {
        guard indexPath.item < chatItems.count else { return nil }
        let item = chatItems[indexPath.item]
        let containerWidth = collectionView.bounds.width
        let layoutData = ChatMapper.calculateLayout(for: item, containerWidth: containerWidth)
        return layoutData
    }
    
    private func handleNewChatItems(_ items: [ChatItem]) {
        let currentIds = items.map { $0.id }
        let newIds = Set(currentIds).subtracting(Set(lastItemIds))

        let isInitialLoad = !hasAppliedInitialSnapshot
        let isPagination: Bool

        if let pendingCount = pendingPaginationCount {
            isPagination = items.count >= pendingCount
            if isPagination {
                pendingPaginationCount = nil
            }
        } else {
            isPagination = isLoadingMore
        }

        let isNewMessage = !newIds.isEmpty && !isPagination && hasAppliedInitialSnapshot
        let isAtBottomNow = isAtBottom()

        var shouldScrollToBottom = false
        var shouldShowToast = false

        if isInitialLoad {
            shouldScrollToBottom = true
        } else if isPagination {
            shouldScrollToBottom = false
        } else if isNewMessage {
            if let newItem = items.first(where: { newIds.contains($0.id) }),
               case .message(let model) = newItem {
                let isMyMessage = model.senderType == .me

                if isMyMessage {
                    shouldScrollToBottom = true
                    lastSentMessageId = nil
                } else {
                    if isAtBottomNow {
                        shouldScrollToBottom = true
                    } else {
                        shouldShowToast = true
                    }
                }
            }
        }

        applySnapshot(with: items, shouldScrollToBottom: shouldScrollToBottom, isPagination: isPagination)

        if shouldShowToast {
            showToast()
        } else {
            hideToast()
        }
    }

    func applySnapshot(
        with items: [ChatItem],
        shouldScrollToBottom: Bool = false,
        animatingDifferences: Bool = true,
        isPagination: Bool = false
    ) {
        chatItems = items
        let currentIds = items.map { $0.id }

        let hasFailedMessage = items.contains { item in
            if case .message(let model) = item {
                return model.status == .failed
            }
            return false
        }

        let isCountIncreased = items.count > lastItemIds.count
        let isNewMessage = isCountIncreased && !isPagination && hasAppliedInitialSnapshot
        let isInitialLoad = !hasAppliedInitialSnapshot
        let shouldAnimate = animatingDifferences && isNewMessage && !hasFailedMessage && !isInitialLoad && !isPagination

        let previousContentHeight = collectionView.contentSize.height
        let previousOffsetY = collectionView.contentOffset.y

        var snapshot = NSDiffableDataSourceSnapshot<Section, ChatItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)

        if !shouldAnimate {
            UIView.performWithoutAnimation {
                dataSource.apply(snapshot, animatingDifferences: false) { [weak self] in
                    self?.handleSnapshotCompletion(
                        items: items,
                        isPagination: isPagination,
                        isNewMessage: isNewMessage,
                        shouldScrollToBottom: shouldScrollToBottom,
                        shouldAnimate: shouldAnimate,
                        previousContentHeight: previousContentHeight,
                        previousOffsetY: previousOffsetY
                    )
                }
            }
        } else {
            dataSource.apply(snapshot, animatingDifferences: true) { [weak self] in
                self?.handleSnapshotCompletion(
                    items: items,
                    isPagination: isPagination,
                    isNewMessage: isNewMessage,
                    shouldScrollToBottom: shouldScrollToBottom,
                    shouldAnimate: shouldAnimate,
                    previousContentHeight: previousContentHeight,
                    previousOffsetY: previousOffsetY
                )
            }
        }

        lastItemIds = currentIds
    }

    private func handleSnapshotCompletion(
        items: [ChatItem],
        isPagination: Bool,
        isNewMessage: Bool,
        shouldScrollToBottom: Bool,
        shouldAnimate: Bool,
        previousContentHeight: CGFloat,
        previousOffsetY: CGFloat
    ) {
        if !hasAppliedInitialSnapshot && items.count > 0 {
            collectionView.isHidden = false
            collectionView.setNeedsLayout()
            collectionView.layoutIfNeeded()

            let contentHeight = collectionView.contentSize.height
            let scrollViewHeight = collectionView.bounds.height
            let maxOffsetY = max(0, contentHeight - scrollViewHeight)

            collectionView.contentOffset = CGPoint(x: 0, y: maxOffsetY)
            hasAppliedInitialSnapshot = true
            didInitialScroll = true

        } else if isPagination {
            let newContentHeight = collectionView.contentSize.height
            let heightDifference = newContentHeight - previousContentHeight

            if heightDifference > 0 {
                let newOffsetY = previousOffsetY + heightDifference
                collectionView.contentOffset = CGPoint(x: 0, y: newOffsetY)
            }
        } else if isNewMessage && shouldScrollToBottom {
            scrollToBottom(animated: shouldAnimate)
        }
    }

    private func isAtBottom() -> Bool {
        let contentHeight = collectionView.contentSize.height
        let scrollViewHeight = collectionView.bounds.height
        let offsetY = collectionView.contentOffset.y
        let maxOffsetY = max(0, contentHeight - scrollViewHeight)

        return offsetY >= maxOffsetY - ChatConstants.Pagination.bottomThreshold
    }

    private func scrollToBottom(animated: Bool) {
        guard collectionView.numberOfItems(inSection: 0) > 0 else { return }

        let lastItem = collectionView.numberOfItems(inSection: 0) - 1
        let indexPath = IndexPath(item: lastItem, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .bottom, animated: animated)
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        let previousKeyboardHeight = keyboardHeight
        keyboardHeight = keyboardFrame.height

        let contentHeight = collectionView.contentSize.height
        let scrollViewHeight = collectionView.bounds.height
        let currentOffsetY = collectionView.contentOffset.y

        let maxOffsetY = max(0, contentHeight - scrollViewHeight)
        let isNearBottom = currentOffsetY >= maxOffsetY - 100

        if isNearBottom {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.scrollToBottom(animated: true)
            }
            return
        }

        let keyboardHeightDifference = keyboardHeight - previousKeyboardHeight

        if keyboardHeightDifference > 0 {
            let adjustedOffsetY = currentOffsetY + keyboardHeightDifference

            UIView.animate(withDuration: duration) {
                self.collectionView.contentOffset.y = adjustedOffsetY
            }
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        let previousKeyboardHeight = keyboardHeight
        keyboardHeight = 0

        let contentHeight = collectionView.contentSize.height
        let scrollViewHeight = collectionView.bounds.height
        let currentOffsetY = collectionView.contentOffset.y

        let maxOffsetY = max(0, contentHeight - scrollViewHeight)
        let isNearBottom = currentOffsetY >= maxOffsetY - 100

        if isNearBottom {
            return
        }

        let adjustedOffsetY = max(0, currentOffsetY - previousKeyboardHeight)

        UIView.animate(withDuration: duration) {
            self.collectionView.contentOffset.y = adjustedOffsetY
        }
    }
}

extension ChatViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y

        guard hasAppliedInitialSnapshot && didInitialScroll else {
            return
        }

        guard !isLoadingMore else {
            return
        }

        guard pendingPaginationCount == nil else {
            return
        }

        guard offsetY <= Layout.paginationThreshold else {
            return
        }

        guard scrollView.contentSize.height > scrollView.bounds.height else {
            return
        }

        pendingPaginationCount = chatItems.count + 1
        viewModel.loadMoreMessages()
    }
}

extension ChatViewController: ChatMessageCellDelegate {
    func chatMessageCell(_ cell: ChatMessageCell, didTapImageAt index: Int, in urls: [String]) {
        presentImageViewer(
            imageUrls: urls,
            initialIndex: index,
            transitionSource: nil
        )
    }
    
    func chatMessageCell(_ cell: ChatMessageCell, didTapVideo url: String) {
        AppMediaService.shared.playVideo(url: url, from: self)
    }
    
    func chatMessageCell(_ cell: ChatMessageCell, didTapFile fileInfo: ChatMessageContent.FileInfo) {
        AppMediaService.shared.previewFile(url: fileInfo.url, fileName: fileInfo.fileName, from: self)
    }

    func chatMessageCell(_ cell: ChatMessageCell, didTapShareCard payload: ShareCardPayload) {
        viewModel.coordinator?.showSharedVideo(videoId: payload.videoId)
    }

    func chatMessageCell(_ cell: ChatMessageCell, didTapProfile userId: String) {
        viewModel.coordinator?.showUserProfile(userId: userId)
    }

    func chatMessageCellDidTapRetry(_ cell: ChatMessageCell, messageId: String) {
        viewModel.retryMessage(messageId: messageId)
    }
    
    func chatMessageCellDidTapDelete(_ cell: ChatMessageCell, messageId: String) {
        viewModel.deleteMessage(messageId: messageId)
    }
}
