//
//  ChatViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/10/26.
//

import UIKit
import Combine
import SnapKit

final class ChatViewController: BaseViewController<ChatViewModel>, ImageViewerPresentable {
    override var navigationBarHidden: Bool { false }
    
    private let tableView = UITableView()
    private let chatInputView = ChatInputView()
    
    private var dataSource: UITableViewDiffableDataSource<Section, ChatItem>!
    private let heightCache = CellHeightCache()
    private var lastItemIds: [String] = []
    private var hasAppliedInitialSnapshot = false
    private var isLoadingMore = false
    private var lastContentHeight: CGFloat = 0

    private enum Section: Hashable {
        case main
    }

    private enum Layout {
        static let estimatedRowHeight: CGFloat = 75
        static let paginationThreshold: CGFloat = 300
    }
    
    override func setupUI() {
        super.setupUI()
        view.backgroundColor = AppColor.gray0
        navigationItem.title = viewModel.title ?? "채팅"

        setupTableView()
        setupInputView()
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ChatSocketService.shared.disconnect()
        ChatRoomContextManager.shared.leave(roomId: viewModel.roomId)
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
                let shouldScroll = !self.hasAppliedInitialSnapshot || self.isAtBottom()
                self.applySnapshot(with: items, shouldScrollToBottom: shouldScroll && !self.isLoadingMore)
            }
            .store(in: &cancellables)

        output.isLoadingMore
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.isLoadingMore = isLoading
            }
            .store(in: &cancellables)

        chatInputView.onSendMessage = { [weak sendMessageSubject] message, attachments in
            let payload = ChatViewModel.SendMessagePayload(content: message, attachments: attachments)
            sendMessageSubject?.send(payload)
        }
        
        viewDidLoadSubject.send(())
    }
    
    private func setupTableView() {
        tableView.backgroundColor = AppColor.gray0
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.alwaysBounceVertical = true
        tableView.showsVerticalScrollIndicator = false

        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)

        tableView.estimatedRowHeight = Layout.estimatedRowHeight
        tableView.rowHeight = UITableView.automaticDimension

        setKeyboardDismissMode(.interactive, for: tableView)

        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: ChatMessageCell.reuseIdentifier)
        tableView.register(ChatDateSeparatorCell.self, forCellReuseIdentifier: ChatDateSeparatorCell.reuseIdentifier)

        tableView.delegate = self

        view.addSubview(tableView)
        view.addSubview(chatInputView)
    }
    
    private func setupInputView() {
        chatInputView.parentViewController = self
    }
    
    private func setupConstraints() {
        tableView.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.equalTo(chatInputView.snp.top)
        }
        
        chatInputView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.keyboardLayoutGuide.snp.top)
        }
    }
    
    
    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource<Section, ChatItem>(
            tableView: tableView
        ) { [weak self] tableView, indexPath, item in
            switch item {
            case .message(let model):
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: ChatMessageCell.reuseIdentifier,
                    for: indexPath
                ) as? ChatMessageCell else {
                    return UITableViewCell()
                }
                cell.delegate = self
                cell.configure(with: model)
                return cell
                
            case .dateSeparator(let separator):
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: ChatDateSeparatorCell.reuseIdentifier,
                    for: indexPath
                ) as? ChatDateSeparatorCell else {
                    return UITableViewCell()
                }
                cell.configure(text: separator.text)
                return cell
            }
        }
    }
    
    func applySnapshot(
        with items: [ChatItem],
        shouldScrollToBottom: Bool = false,
        animatingDifferences: Bool = true
    ) {
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

        let previousContentHeight = tableView.contentSize.height
        let previousOffsetY = tableView.contentOffset.y

        var snapshot = NSDiffableDataSourceSnapshot<Section, ChatItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)

        dataSource.apply(snapshot, animatingDifferences: shouldAnimate) { [weak self] in
            guard let self = self else { return }

            if !self.hasAppliedInitialSnapshot {
                self.tableView.layoutIfNeeded()
                self.tableView.setContentOffset(.zero, animated: false)
            } else if isPagination {
                let newContentHeight = self.tableView.contentSize.height
                let heightDifference = newContentHeight - previousContentHeight

                if heightDifference > 0 {
                    let newOffsetY = previousOffsetY + heightDifference
                    self.tableView.contentOffset = CGPoint(x: 0, y: newOffsetY)
                }
            } else if isNewMessage && shouldScrollToBottom {
                self.scrollToBottom(animated: shouldAnimate)
            }
        }

        lastItemIds = currentIds
        hasAppliedInitialSnapshot = true
    }

    private func isAtBottom() -> Bool {
        return tableView.contentOffset.y <= 100
    }

    private func scrollToBottom(animated: Bool) {
        guard tableView.numberOfRows(inSection: 0) > 0 else { return }

        let indexPath = IndexPath(row: 0, section: 0)
        tableView.scrollToRow(at: indexPath, at: .top, animated: animated)
    }
}

extension ChatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let item = dataSource.itemIdentifier(for: indexPath) else {
            return Layout.estimatedRowHeight
        }

        if let cachedHeight = heightCache.height(for: item.id) {
            return cachedHeight
        }

        return Layout.estimatedRowHeight
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }

        let height = cell.frame.size.height
        heightCache.setHeight(height, for: item.id)

        if indexPath.row <= 4 {
            checkAndLoadMore()
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentHeight = scrollView.contentSize.height
        let scrollViewHeight = scrollView.bounds.height
        let offsetY = scrollView.contentOffset.y
        let maxOffsetY = max(0, contentHeight - scrollViewHeight)

        if offsetY >= maxOffsetY - Layout.paginationThreshold {
            checkAndLoadMore()
        }
    }

    private func checkAndLoadMore() {
        guard !isLoadingMore else { return }
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

