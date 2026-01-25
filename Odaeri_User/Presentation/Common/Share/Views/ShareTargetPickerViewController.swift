//
//  ShareTargetPickerViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/24/26.
//

import UIKit
import Combine
import SnapKit

final class ShareTargetPickerViewController: BaseViewController<ShareTargetPickerViewModel> {
    private enum Section {
        case main
    }

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let searchTextSubject = PassthroughSubject<String, Never>()
    private let targetSelectedSubject = PassthroughSubject<String, Never>()
    private let sendTappedSubject = PassthroughSubject<Void, Never>()

    private let searchBar = SearchBar(placeholder: "유저 검색")
    private let emptyView = ShareTargetEmptyView()

    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("전송", for: .normal)
        button.titleLabel?.font = AppFont.body1Bold
        button.setTitleColor(AppColor.gray0, for: .normal)
        button.backgroundColor = AppColor.gray45
        button.layer.cornerRadius = 12
        button.isEnabled = false
        return button
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = Layout.itemSpacing
        layout.minimumLineSpacing = Layout.lineSpacing
        layout.sectionInset = Layout.sectionInset
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = AppColor.gray0
        view.allowsMultipleSelection = false
        return view
    }()

    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, ShareTargetDisplayModel> = {
        UICollectionViewDiffableDataSource<Section, ShareTargetDisplayModel>(
            collectionView: collectionView
        ) { collectionView, indexPath, model in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ShareTargetCell.reuseIdentifier,
                for: indexPath
            ) as? ShareTargetCell else {
                return UICollectionViewCell()
            }
            cell.configure(with: model)
            return cell
        }
    }()

    private enum Layout {
        static let itemSpacing: CGFloat = 12
        static let lineSpacing: CGFloat = 16
        static let sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        static let sendButtonHeight: CGFloat = 48
        static let contentSpacing: CGFloat = 16
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewDidLoadSubject.send(())
    }

    override func setupUI() {
        super.setupUI()

        view.backgroundColor = AppColor.gray0

        view.addSubview(searchBar)
        view.addSubview(collectionView)
        view.addSubview(emptyView)
        view.addSubview(sendButton)

        searchBar.searchBar.delegate = self
        emptyView.isHidden = true

        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(Layout.contentSpacing)
            make.leading.trailing.equalToSuperview().inset(Layout.contentSpacing)
            make.height.equalTo(40)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(Layout.contentSpacing)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(sendButton.snp.top).offset(-Layout.contentSpacing)
        }

        emptyView.snp.makeConstraints { make in
            make.edges.equalTo(collectionView)
        }

        sendButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Layout.contentSpacing)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-Layout.contentSpacing)
            make.height.equalTo(Layout.sendButtonHeight)
        }

        collectionView.register(ShareTargetCell.self, forCellWithReuseIdentifier: ShareTargetCell.reuseIdentifier)
        collectionView.delegate = self

        sendButton.tapPublisher()
            .sink { [weak self] _ in
                self?.sendTappedSubject.send(())
            }
            .store(in: &cancellables)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateItemSize()
    }

    override func bind() {
        super.bind()

        let input = ShareTargetPickerViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            searchText: searchTextSubject.eraseToAnyPublisher(),
            targetSelected: targetSelectedSubject.eraseToAnyPublisher(),
            sendTapped: sendTappedSubject.eraseToAnyPublisher()
        )

        let output = viewModel.transform(input: input)

        output.items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.applySnapshot(items: items)
            }
            .store(in: &cancellables)

        output.isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.setLoading(isLoading)
            }
            .store(in: &cancellables)

        output.emptyState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                if let state {
                    self.emptyView.configure(title: state.title, subtitle: state.subtitle)
                    self.emptyView.isHidden = false
                    self.collectionView.isHidden = true
                } else {
                    self.emptyView.isHidden = true
                    self.collectionView.isHidden = false
                }
            }
            .store(in: &cancellables)

        output.isSendEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEnabled in
                guard let self = self else { return }
                self.sendButton.isEnabled = isEnabled
                self.sendButton.backgroundColor = isEnabled ? AppColor.blackSprout : AppColor.gray45
            }
            .store(in: &cancellables)

        output.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showAlert(title: "오류", message: message)
            }
            .store(in: &cancellables)

        output.didSend
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.dismiss(animated: true)
            }
            .store(in: &cancellables)
    }

    private func applySnapshot(items: [ShareTargetDisplayModel]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, ShareTargetDisplayModel>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func updateItemSize() {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let inset = Layout.sectionInset.left + Layout.sectionInset.right
        let spacing = Layout.itemSpacing * 3
        let availableWidth = collectionView.bounds.width - inset - spacing
        let itemWidth = max(0, availableWidth / 4)
        let itemHeight = itemWidth + 26
        if layout.itemSize.width != itemWidth || layout.itemSize.height != itemHeight {
            layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
            layout.invalidateLayout()
        }
    }
}

extension ShareTargetPickerViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchTextSubject.send(searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension ShareTargetPickerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        targetSelectedSubject.send(item.userId)
    }
}
