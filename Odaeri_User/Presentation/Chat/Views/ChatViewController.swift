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
    private var lastSentMessageId: String?
    private var didLogInitialSnapshot = false
    private var didLogInitialScroll = false
    private var didInitialScroll = false
    private var lastPaginationTrigger = "unknown"
    private var keyboardHeight: CGFloat = 0

    private enum Section: Hashable {
        case main
    }

    private enum Layout {
        static let paginationThreshold: CGFloat = 300
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
            .sink { success in
                if success {
                    print("채팅방 읽음 처리 완료: \(self.viewModel.roomId)")
                } else {
                    print("채팅방 읽음 처리 실패: \(self.viewModel.roomId)")
                }
            }
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
        return ChatMapper.calculateLayout(for: item, containerWidth: containerWidth)
    }
    
    private func handleNewChatItems(_ items: [ChatItem]) {
        let currentIds = items.map { $0.id }
        let newIds = Set(currentIds).subtracting(Set(lastItemIds))

        let isInitialLoad = !hasAppliedInitialSnapshot
        let isPagination = isLoadingMore
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

        applySnapshot(with: items, shouldScrollToBottom: shouldScrollToBottom)

        if shouldShowToast {
            showToast()
        } else {
            hideToast()
        }
    }

    func applySnapshot(
        with items: [ChatItem],
        shouldScrollToBottom: Bool = false,
        animatingDifferences: Bool = true
    ) {
#if DEBUG
        let snapshotStart = CACurrentMediaTime()
#endif
        chatItems = items
        let currentIds = items.map { $0.id }

        let hasFailedMessage = items.contains { item in
            if case .message(let model) = item {
                return model.status == .failed
            }
            return false
        }

        let isCountIncreased = items.count > lastItemIds.count
        let isPagination = isLoadingMore
        let isNewMessage = isCountIncreased && !isPagination && hasAppliedInitialSnapshot
        let isInitialLoad = !hasAppliedInitialSnapshot
        let shouldAnimate = animatingDifferences && isNewMessage && !hasFailedMessage && !isInitialLoad

        let previousContentHeight = collectionView.contentSize.height
        let previousOffsetY = collectionView.contentOffset.y

        var snapshot = NSDiffableDataSourceSnapshot<Section, ChatItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)

        dataSource.apply(snapshot, animatingDifferences: shouldAnimate) { [weak self] in
            guard let self = self else { return }

            if !self.hasAppliedInitialSnapshot && items.count > 0 {
                self.collectionView.isHidden = false
                self.collectionView.setNeedsLayout()
                self.collectionView.layoutIfNeeded()

                let contentHeight = self.collectionView.contentSize.height
                let scrollViewHeight = self.collectionView.bounds.height
                let maxOffsetY = max(0, contentHeight - scrollViewHeight)

                self.collectionView.contentOffset = CGPoint(x: 0, y: maxOffsetY)
                self.hasAppliedInitialSnapshot = true
                self.didInitialScroll = true

                if !self.didLogInitialSnapshot {
                    print("[ChatSnapshot] initial applied: items=\(items.count), contentSize=\(self.collectionView.contentSize), bounds=\(self.collectionView.bounds.size), offset=\(self.collectionView.contentOffset), isLoadingMore=\(self.isLoadingMore)")
                    self.didLogInitialSnapshot = true
                }
            } else if isPagination {
                let newContentHeight = self.collectionView.contentSize.height
                let heightDifference = newContentHeight - previousContentHeight

                if heightDifference > 0 {
                    let newOffsetY = previousOffsetY + heightDifference
                    self.collectionView.contentOffset = CGPoint(x: 0, y: newOffsetY)
                }
            } else if isNewMessage && shouldScrollToBottom {
                self.scrollToBottom(animated: shouldAnimate)
            }

#if DEBUG
            let durationMs = (CACurrentMediaTime() - snapshotStart) * 1000
            print("[ChatSnapshotTiming] items=\(items.count), initial=\(isInitialLoad), pagination=\(isPagination), animate=\(shouldAnimate), durationMs=\(String(format: "%.2f", durationMs))")
#endif
        }

        lastItemIds = currentIds
    }

    private func isAtBottom() -> Bool {
        let contentHeight = collectionView.contentSize.height
        let scrollViewHeight = collectionView.bounds.height
        let offsetY = collectionView.contentOffset.y
        let maxOffsetY = max(0, contentHeight - scrollViewHeight)

        return offsetY >= maxOffsetY - 100
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
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        keyboardHeight = keyboardFrame.height

        let contentHeight = collectionView.contentSize.height
        let scrollViewHeight = collectionView.bounds.height
        let currentOffsetY = collectionView.contentOffset.y

        let maxOffsetY = max(0, contentHeight - scrollViewHeight)
        let isNearBottom = currentOffsetY >= maxOffsetY - 100

        if isNearBottom {
            DispatchQueue.main.async {
                self.scrollToBottom(animated: true)
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
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item <= 4 {
            lastPaginationTrigger = "willDisplay"
            checkAndLoadMore()
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y

        if !didLogInitialScroll, hasAppliedInitialSnapshot {
            print("[ChatScroll] first scroll: offsetY=\(offsetY), contentHeight=\(scrollView.contentSize.height), boundsHeight=\(scrollView.bounds.height), isLoadingMore=\(isLoadingMore)")
            didLogInitialScroll = true
        }

        if offsetY <= Layout.paginationThreshold {
            lastPaginationTrigger = "scroll"
            checkAndLoadMore()
        }
    }

    private func checkAndLoadMore() {
        guard hasAppliedInitialSnapshot && didInitialScroll else {
            return
        }
        guard !isLoadingMore else { return }
        print("[ChatPagination] trigger=\(lastPaginationTrigger), offsetY=\(collectionView.contentOffset.y), contentHeight=\(collectionView.contentSize.height)")
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
