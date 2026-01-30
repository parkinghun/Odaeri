//
//  StoreSearchViewController.swift
//  Odaeri
//
//  Created by 박성훈 on 01/16/26.
//

import UIKit
import Combine
import SnapKit

final class StoreSearchViewController: BaseViewController<StoreSearchViewModel> {
    weak var delegate: StoreSearchDelegate?

    private let viewType: StoreSearchViewType
    private var currentState: StoreSearchViewState = .initial("")
    private var searchResults: [StoreSearchListItem] = []
    private var nearbyStores: [StoreSearchListItem] = []
    private var recentStores: [RecentStoreItem] = []

    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "가게 이름을 검색해보세요"
        return searchBar
    }()

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = AppColor.gray0
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = AppColor.gray30
        tableView.keyboardDismissMode = .onDrag
        tableView.register(StoreSearchCell.self, forCellReuseIdentifier: StoreSearchCell.identifier)
        return tableView
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body1
        label.textColor = AppColor.gray60
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let searchButtonTappedSubject = PassthroughSubject<String, Never>()

    init(viewModel: StoreSearchViewModel, viewType: StoreSearchViewType) {
        self.viewType = viewType
        super.init(viewModel: viewModel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupConstraints()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if viewType == .home {
            searchBar.becomeFirstResponder()
        }
    }

    override func setupUI() {
        super.setupUI()

        view.backgroundColor = AppColor.gray0

        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
    }

    private func setupConstraints() {
        searchBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(56)
        }

        tableView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        emptyLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(40)
        }
    }

    override func bind() {
        super.bind()

        let viewDidLoadSubject = PassthroughSubject<Void, Never>()

        let input = StoreSearchViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            searchButtonTapped: searchButtonTappedSubject
                .removeDuplicates()
                .eraseToAnyPublisher()
        )

        let output = viewModel.transform(input: input)

        if let initialQuery = viewModel.initialSearchQuery {
            searchBar.text = initialQuery
        }

        output.viewState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.currentState = state
                self?.updateViewState(state)
            }
            .store(in: &cancellables)

        output.searchResults
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stores in
                self?.searchResults = stores
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)

        output.nearbyStores
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stores in
                self?.nearbyStores = stores
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)

        output.recentStores
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stores in
                self?.recentStores = stores
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)

        output.isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.setLoading(isLoading)
            }
            .store(in: &cancellables)

        output.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                self?.showAlert(title: "오류", message: errorMessage)
            }
            .store(in: &cancellables)

        viewDidLoadSubject.send()
    }

    private func setupNavigationBar() {
        title = viewType.navigationTitle
        navigationController?.navigationBar.prefersLargeTitles = false
    }

    private func updateViewState(_ state: StoreSearchViewState) {
        tableView.isHidden = !state.shouldShowTableView
        emptyLabel.isHidden = !state.shouldShowEmptyLabel

        if let message = state.emptyMessage {
            emptyLabel.text = message
        }

        if state.shouldShowTableView {
            tableView.reloadData()
        }
    }
}

extension StoreSearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        let searchText = searchBar.text ?? ""
        searchButtonTappedSubject.send(searchText)
    }
}

extension StoreSearchViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch currentState {
        case .results:
            return searchResults.count
        case .nearbyStores:
            return nearbyStores.count
        case .recentStores:
            return recentStores.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: StoreSearchCell.identifier,
            for: indexPath
        ) as? StoreSearchCell else {
            return UITableViewCell()
        }

        switch currentState {
        case .results:
            let item = searchResults[indexPath.row]
            cell.configure(with: item)
        case .nearbyStores:
            let item = nearbyStores[indexPath.row]
            cell.configure(with: item)
        case .recentStores:
            let item = recentStores[indexPath.row]
            cell.configure(with: item)
        default:
            break
        }

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return currentState.sectionTitle
    }
}

extension StoreSearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storeId: String

        switch currentState {
        case .results:
            storeId = searchResults[indexPath.row].store.storeId
        case .nearbyStores:
            storeId = nearbyStores[indexPath.row].store.storeId
        case .recentStores:
            storeId = recentStores[indexPath.row].store.id
        default:
            return
        }

        delegate?.didSelectStore(storeId: storeId)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}
