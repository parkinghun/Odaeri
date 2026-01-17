//
//  CommunityViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 12/24/25.
//

import UIKit
import Combine
import SnapKit

final class CommunityViewController: BaseViewController<CommunityViewModel> {
    private let searchBar = SearchBar()

    private let chatButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = AppColor.deepSprout
        button.layer.cornerRadius = 8
        button.setImage(AppImage.chat, for: .normal)
        button.tintColor = AppColor.gray0
        return button
    }()

    private let chatBadgeView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = 5
        view.isHidden = true
        return view
    }()

    private let writeButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = AppColor.deepSprout
        button.layer.cornerRadius = 8
        button.setImage(AppImage.write, for: .normal)
        button.tintColor = AppColor.gray0
        return button
    }()

    private lazy var topStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [searchBar, chatButton, writeButton])
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.small
        stackView.alignment = .center
        return stackView
    }()

    private let distanceView = CommunityDistanceView()

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = true
        tableView.backgroundColor = AppColor.gray15
        tableView.estimatedRowHeight = 400
        tableView.rowHeight = UITableView.automaticDimension
        return tableView
    }()

    private let headerView = CommunityTimelineHeaderView()

    private typealias DataSource = UITableViewDiffableDataSource<CommunitySection, CommunityPostItemViewModel>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<CommunitySection, CommunityPostItemViewModel>
    private var dataSource: DataSource?

    private let userScrolledBannerSubject = PassthroughSubject<Int, Never>()
    private let sortSelectedSubject = PassthroughSubject<CommunitySortType, Never>()
    private let postLikeToggledSubject = PassthroughSubject<CommunityPostLikeEvent, Never>()
    private let bannerSelectedSubject = PassthroughSubject<BannerEntity, Never>()
    private let storeSelectedSubject = PassthroughSubject<String, Never>()
    private let creatorSelectedSubject = PassthroughSubject<String, Never>()
    private let postDetailRequestedSubject = PassthroughSubject<String, Never>()
    private let postEditRequestedSubject = PassthroughSubject<String, Never>()
    private let postDeleteRequestedSubject = PassthroughSubject<String, Never>()
    private let searchTextSubject = PassthroughSubject<String, Never>()

    private let emptyView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray15
        view.isHidden = true

        let label = UILabel()
        label.text = "검색 결과가 없습니다"
        label.font = AppFont.body1
        label.textColor = AppColor.gray60
        label.textAlignment = .center
        view.addSubview(label)

        label.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        return view
    }()

    private enum Layout {
        static let actionButtonSize: CGFloat = 40
        static let badgeSize: CGFloat = 10
    }
    
    override func setupUI() {
        super.setupUI()
        setKeyboardDismissMode(.onDrag, for: tableView)

        view.backgroundColor = AppColor.gray15

        view.addSubview(topStackView)
        view.addSubview(distanceView)
        view.addSubview(tableView)
        view.addSubview(emptyView)

        writeButton.snp.makeConstraints {
            $0.size.equalTo(Layout.actionButtonSize)
        }

        chatButton.snp.makeConstraints {
            $0.size.equalTo(Layout.actionButtonSize)
        }

        chatButton.addSubview(chatBadgeView)
        chatBadgeView.snp.makeConstraints {
            $0.size.equalTo(Layout.badgeSize)
            $0.top.equalToSuperview().offset(4)
            $0.trailing.equalToSuperview().offset(-4)
        }

        topStackView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.horizontalEdges.equalToSuperview().inset(AppSpacing.screenMargin)
            $0.height.equalTo(56)
        }

        distanceView.snp.makeConstraints {
            $0.top.equalTo(topStackView.snp.bottom).offset(AppSpacing.xLarge)
            $0.horizontalEdges.equalToSuperview().inset(AppSpacing.screenMargin)
        }

        tableView.snp.makeConstraints {
            $0.top.equalTo(distanceView.snp.bottom).offset(AppSpacing.xLarge)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        emptyView.snp.makeConstraints {
            $0.edges.equalTo(tableView)
        }

        searchBar.searchBar.delegate = self

        tableView.register(CommunityPostCell.self, forCellReuseIdentifier: CommunityPostCell.reuseIdentifier)
        tableView.tableHeaderView = headerView
        configureDataSource()

        headerView.onUserScrolledBanner = { [weak self] index in
            self?.userScrolledBannerSubject.send(index)
        }
        headerView.onSortSelected = { [weak self] sortType in
            self?.sortSelectedSubject.send(sortType)
        }
        headerView.onBannerSelected = { [weak self] banner in
            self?.bannerSelectedSubject.send(banner)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateHeaderHeightIfNeeded()
    }

    override func bind() {
        super.bind()

        let viewDidLoadSubject = PassthroughSubject<Void, Never>()
        let distanceIndexSubject = PassthroughSubject<Int, Never>()

        distanceView.onIndexSelected = { index in
            distanceIndexSubject.send(index)
        }

        let input = CommunityViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            writeButtonTapped: writeButton.tapPublisher(),
            chatButtonTapped: chatButton.tapPublisher(),
            storeSelected: storeSelectedSubject.eraseToAnyPublisher(),
            creatorSelected: creatorSelectedSubject.eraseToAnyPublisher(),
            postDetailRequested: postDetailRequestedSubject.eraseToAnyPublisher(),
            distanceIndexSelected: distanceIndexSubject.eraseToAnyPublisher(),
            sortSelected: sortSelectedSubject.eraseToAnyPublisher(),
            userScrolledBanner: userScrolledBannerSubject.eraseToAnyPublisher(),
            bannerSelected: bannerSelectedSubject.eraseToAnyPublisher(),
            postLikeToggled: postLikeToggledSubject.eraseToAnyPublisher(),
            postEditRequested: postEditRequestedSubject.eraseToAnyPublisher(),
            postDeleteRequested: postDeleteRequestedSubject.eraseToAnyPublisher(),
            searchText: searchTextSubject
                .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
                .eraseToAnyPublisher()
        )
        let output = viewModel.transform(input: input)

        output.distanceSelection
            .receive(on: DispatchQueue.main)
            .sink { [weak self] selection in
                self?.distanceView.apply(selection: selection)
            }
            .store(in: &cancellables)

        output.sortSelection
            .receive(on: DispatchQueue.main)
            .sink { [weak self] selection in
                self?.headerView.updateSortSelection(selection)
            }
            .store(in: &cancellables)

        output.banners
            .receive(on: DispatchQueue.main)
            .sink { [weak self] banners in
                self?.headerView.updateBanners(banners)
            }
            .store(in: &cancellables)

        output.currentBannerIndex
            .receive(on: DispatchQueue.main)
            .sink { [weak self] index in
                self?.headerView.scrollToBanner(at: index)
            }
            .store(in: &cancellables)

        output.posts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] posts in
                self?.applySnapshot(items: posts)
            }
            .store(in: &cancellables)

        output.isEmpty
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEmpty in
                self?.emptyView.isHidden = !isEmpty
                self?.tableView.isHidden = isEmpty
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

        RealmChatRepository.shared.hasAnyUnreadRoom()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hasUnread in
                self?.chatBadgeView.isHidden = !hasUnread
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send(())
    }

    private func configureDataSource() {
        dataSource = DataSource(tableView: tableView) { [weak self] tableView, indexPath, item in
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: CommunityPostCell.reuseIdentifier,
                for: indexPath
            ) as? CommunityPostCell else {
                return UITableViewCell()
            }

            cell.cancellables.removeAll()
            cell.configure(with: item)
            cell.onVideoSelected = { [weak self] videoURL in
                guard let self = self else { return }
                AppMediaService.shared.playVideo(url: videoURL, from: self)
            }
            cell.onStoreInfoTapped = { [weak self] storeId in
                self?.storeSelectedSubject.send(storeId)
            }
            cell.onCreatorTapped = { [weak self] creatorId in
                self?.creatorSelectedSubject.send(creatorId)
            }
            cell.onEditTapped = { [weak self] postId in
                self?.postEditRequestedSubject.send(postId)
            }
            cell.onDeleteTapped = { [weak self] postId in
                self?.showDeleteConfirmation(postId: postId)
            }
            cell.contentTapPublisher
                .sink { [weak self] postId in
                    self?.postDetailRequestedSubject.send(postId)
                }
                .store(in: &cell.cancellables)
            cell.likeTapPublisher
                .sink { [weak self] event in
                    self?.postLikeToggledSubject.send(
                        CommunityPostLikeEvent(postId: event.storeId, newState: event.newState)
                    )
                }
                .store(in: &cell.cancellables)

            return cell
        }

        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        dataSource?.apply(snapshot, animatingDifferences: false)
    }

    private func applySnapshot(items: [CommunityPostItemViewModel]) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        dataSource?.apply(snapshot, animatingDifferences: false)
    }

    private func updateHeaderHeightIfNeeded() {
        guard let headerView = tableView.tableHeaderView else { return }
        let targetSize = CGSize(width: tableView.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let height = headerView.systemLayoutSizeFitting(targetSize).height
        guard headerView.frame.height != height else { return }
        headerView.frame.size.height = height
        tableView.tableHeaderView = headerView
    }

    func refresh() {
        viewModel.refresh()
    }

    private func showDeleteConfirmation(postId: String) {
        let alert = UIAlertController(title: "게시글 삭제", message: "정말 삭제하시겠습니까?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.postDeleteRequestedSubject.send(postId)
        })
        present(alert, animated: true)
    }
}

private enum CommunitySection {
    case main
}

extension CommunityViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchTextSubject.send(searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchTextSubject.send("")
    }
}
