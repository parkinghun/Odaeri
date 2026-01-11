//
//  ChatViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/10/26.
//

import UIKit
import Combine
import SnapKit

final class ChatViewController: BaseViewController<ChatViewModel> {
    override var navigationBarHidden: Bool { false }

    private let tableView = UITableView()
    private let chatInputView = ChatInputView()

    private var dataSource: UITableViewDiffableDataSource<Section, ChatItem>!
    private let heightCache = CellHeightCache()

    private enum Section: Hashable {
        case main
    }

    private enum Layout {
        static let estimatedRowHeight: CGFloat = 75
        static let scrollThreshold: CGFloat = 100
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

    override func bind() {
        super.bind()

        let viewDidLoadSubject = PassthroughSubject<Void, Never>()
        let sendMessageSubject = PassthroughSubject<String, Never>()

        let input = ChatViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            sendMessage: sendMessageSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.chatItems
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.applySnapshot(with: items, shouldScrollToBottom: true)
            }
            .store(in: &cancellables)

        chatInputView.onSendMessage = { [weak sendMessageSubject] message in
            sendMessageSubject?.send(message)
        }

        viewDidLoadSubject.send(())
    }

    private func setupTableView() {
        tableView.backgroundColor = AppColor.gray0
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        tableView.contentInsetAdjustmentBehavior = .never

        tableView.estimatedRowHeight = Layout.estimatedRowHeight
        tableView.rowHeight = UITableView.automaticDimension

        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: ChatMessageCell.reuseIdentifier)
        tableView.register(ChatDateSeparatorCell.self, forCellReuseIdentifier: ChatDateSeparatorCell.reuseIdentifier)

        tableView.delegate = self

        view.addSubview(tableView)
        view.addSubview(chatInputView)
    }

    private func setupInputView() {
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

            case .dateSeparator(let dateText):
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: ChatDateSeparatorCell.reuseIdentifier,
                    for: indexPath
                ) as? ChatDateSeparatorCell else {
                    return UITableViewCell()
                }
                cell.configure(text: dateText)
                return cell
            }
        }
    }

    func applySnapshot(
        with items: [ChatItem],
        shouldScrollToBottom: Bool = false,
        animatingDifferences: Bool = true
    ) {
        let isAtBottom = isScrolledToBottom()

        var snapshot = NSDiffableDataSourceSnapshot<Section, ChatItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)

        dataSource.apply(snapshot, animatingDifferences: animatingDifferences) { [weak self] in
            if shouldScrollToBottom || isAtBottom {
                self?.scrollToBottom(animated: animatingDifferences)
            }
        }
    }

    private func isScrolledToBottom() -> Bool {
        let contentHeight = tableView.contentSize.height
        let tableViewHeight = tableView.frame.size.height
        let offsetY = tableView.contentOffset.y

        let bottomEdge = contentHeight - tableViewHeight
        let distanceFromBottom = bottomEdge - offsetY

        return distanceFromBottom <= Layout.scrollThreshold
    }

    private func scrollToBottom(animated: Bool) {
        guard tableView.numberOfSections > 0 else { return }

        let lastSection = tableView.numberOfSections - 1
        let lastRow = tableView.numberOfRows(inSection: lastSection) - 1

        guard lastRow >= 0 else { return }

        let indexPath = IndexPath(row: lastRow, section: lastSection)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
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
    }
}

extension ChatViewController: ChatMessageCellDelegate {
    func chatMessageCell(_ cell: ChatMessageCell, didTapImageAt index: Int, in urls: [String]) {
        print("Image tapped at index: \(index), urls: \(urls)")
    }

    func chatMessageCell(_ cell: ChatMessageCell, didTapVideo url: String) {
        print("Video tapped: \(url)")
    }

    func chatMessageCell(_ cell: ChatMessageCell, didTapFile fileInfo: ChatMessageContent.FileInfo) {
        print("File tapped: \(fileInfo.fileName)")
    }
}
