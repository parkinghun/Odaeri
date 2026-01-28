//
//  ChatRoomViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/9/26.
//

import UIKit
import Combine
import SnapKit
final class ChatRoomViewController: BaseViewController<ChatRoomViewModel> {
    private let didPopSubject = PassthroughSubject<Void, Never>()
    private let viewWillAppearSubject = PassthroughSubject<Void, Never>()
    private let emptyView = ChatRoomEmptyView()
    private let roomSelectedSubject = PassthroughSubject<String, Never>()

    private typealias DataSource = UITableViewDiffableDataSource<Section, ChatRoomDisplayModel>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, ChatRoomDisplayModel>

    private enum Section {
        case main
    }

    private lazy var dataSource: DataSource = {
        DataSource(tableView: tableView) { tableView, indexPath, model in
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: ChatRoomListCell.reuseIdentifier,
                for: indexPath
            ) as? ChatRoomListCell else {
                return UITableViewCell()
            }
            cell.configure(with: model)
            return cell
        }
    }()

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorStyle = .none
        tableView.backgroundColor = AppColor.gray0
        tableView.rowHeight = Layout.cellHeight
        tableView.estimatedRowHeight = Layout.cellHeight
        return tableView
    }()

    private enum Layout {
        static let cellHeight: CGFloat = 80
    }

    override func setupUI() {
        super.setupUI()
        view.backgroundColor = AppColor.gray0
        navigationItem.title = "채팅"

        view.addSubview(tableView)

        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        tableView.register(ChatRoomListCell.self, forCellReuseIdentifier: ChatRoomListCell.reuseIdentifier)
        tableView.delegate = self
        tableView.backgroundView = emptyView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearSubject.send(())
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent {
            didPopSubject.send(())
        }
    }

    override func bind() {
        super.bind()

        let input = ChatRoomViewModel.Input(
            viewWillAppear: viewWillAppearSubject.eraseToAnyPublisher(),
            didPop: didPopSubject.eraseToAnyPublisher(),
            roomSelected: roomSelectedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.isLoading
            .sink { [weak self] isLoading in
                self?.setLoading(isLoading)
            }
            .store(in: &cancellables)

        output.error
            .sink { [weak self] message in
                self?.showAlert(title: "오류", message: message)
            }
            .store(in: &cancellables)

        output.rooms
            .sink { [weak self] models in
                self?.applySnapshot(with: models)
            }
            .store(in: &cancellables)

        emptyView.actionTapped
            .sink { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }
            .store(in: &cancellables)
    }

    private func applySnapshot(with displayModels: [ChatRoomDisplayModel]) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(displayModels)

        dataSource.apply(snapshot, animatingDifferences: true)

        updateEmptyView(isEmpty: displayModels.isEmpty)
    }

    private func updateEmptyView(isEmpty: Bool) {
        emptyView.isHidden = !isEmpty
        tableView.backgroundView = isEmpty ? emptyView : nil
    }
}

extension ChatRoomViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let model = dataSource.itemIdentifier(for: indexPath) else { return }
        roomSelectedSubject.send(model.roomId)
    }
}
