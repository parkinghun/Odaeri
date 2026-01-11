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
    private let emptyView = ChatRoomEmptyView()
    private let roomSelectedSubject = PassthroughSubject<ChatRoomEntity, Never>()
    private var chatRooms: [ChatRoomEntity] = []
    private var displayModels: [ChatRoomDisplayModel] = []
    private let currentUserId = "current_user"

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
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundView = emptyView
        updateEmptyView()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent {
            didPopSubject.send(())
        }
    }

    override func bind() {
        super.bind()

        let viewDidLoadSubject = PassthroughSubject<Void, Never>()
        let input = ChatRoomViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            didPop: didPopSubject.eraseToAnyPublisher(),
            roomSelected: roomSelectedSubject.eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.chatRooms
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rooms in
                guard let self = self else { return }
                self.chatRooms = rooms
                self.displayModels = ChatRoomMapper.map(rooms, currentUserId: self.currentUserId)
                self.tableView.reloadData()
                self.updateEmptyView()
            }
            .store(in: &cancellables)

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

        emptyView.actionTapped
            .sink { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
    }

    private func updateEmptyView() {
        emptyView.isHidden = !chatRooms.isEmpty
        tableView.backgroundView = chatRooms.isEmpty ? emptyView : nil
    }
}

extension ChatRoomViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        displayModels.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ChatRoomListCell.reuseIdentifier,
            for: indexPath
        ) as? ChatRoomListCell else {
            return UITableViewCell()
        }

        cell.configure(with: displayModels[indexPath.row])
        return cell
    }
}

extension ChatRoomViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        roomSelectedSubject.send(chatRooms[indexPath.row])
    }
}
