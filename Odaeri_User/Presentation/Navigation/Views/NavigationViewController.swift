//
//  NavigationViewController.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/7/26.
//

import UIKit
import MapKit
import Combine
import SnapKit

final class NavigationViewController: BaseViewController<NavigationViewModel> {

    override var navigationBarHidden: Bool { true }

    private enum CameraMode {
        case tracking
        case browsing
        case stepPreview
    }

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let viewDidDisappearSubject = PassthroughSubject<Void, Never>()
    private let userDidDragMapSubject = PassthroughSubject<Void, Never>()
    private let mapCameraAltitudeChangedSubject = PassthroughSubject<CLLocationDistance, Never>()
    private let rerouteConfirmedSubject = PassthroughSubject<Void, Never>()
    private var viewModelTimeText: String = ""
    private var viewModelDistanceText: String = ""

    private lazy var mapView: MKMapView = {
        let map = MKMapView()
        map.mapType = .standard
        map.showsUserLocation = true
        map.isRotateEnabled = true
        map.isPitchEnabled = true
        return map
    }()

    private let headerView = UIView()
    private let headerCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()
    private let headerCancelButton = UIButton(type: .system)
    private let headerPageControl = UIPageControl()
    private let headerContentView = UIView()
    private let bottomSheetView = NavigationBottomSheetView()

    private let relocateButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let image = UIImage(systemName: "location.fill", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = AppColor.blackSprout
        button.backgroundColor = AppColor.gray0
        button.layer.cornerRadius = 8
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.1
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        return button
    }()

    private var passedPathOverlay: MKPolyline?
    private var remainingPathOverlay: MKPolyline?
    private var destinationAnnotation: MKPointAnnotation?
    private var stepPreviewAnnotation: MKPointAnnotation?
    private var routeSteps: [NavigationRouteStep] = []
    private var currentCameraMode: CameraMode = .tracking
    private var isProgrammaticMove: Bool = false
    private let currentLocationStepId = "current-location-step"
    private var hasAppliedInitialTrackingCamera = false
    private var isHeaderSyncing = false

    private final class NavigationStepAnnotation: MKPointAnnotation {
        let direction: NavigationTurnDirection

        init(coordinate: CLLocationCoordinate2D, title: String?, direction: NavigationTurnDirection) {
            self.direction = direction
            super.init()
            self.coordinate = coordinate
            self.title = title
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapGestureRecognizer()
        addDestinationAnnotation()
        setupHeaderSteps()
        viewDidLoadSubject.send(())
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewDidDisappearSubject.send(())
    }

    override func setupUI() {
        super.setupUI()

        view.addSubview(mapView)
        view.addSubview(headerView)
        view.addSubview(bottomSheetView)
        view.addSubview(relocateButton)

        mapView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        headerView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(140)
        }

        bottomSheetView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-8)
        }

        relocateButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalTo(bottomSheetView.snp.top).offset(-12)
            $0.width.height.equalTo(44)
        }

        headerView.backgroundColor = AppColor.blackSprout
        headerView.addSubview(headerContentView)
        headerContentView.addSubview(headerCollectionView)
        headerView.addSubview(headerCancelButton)
        headerView.addSubview(headerPageControl)

        headerCollectionView.backgroundColor = .clear
        headerCollectionView.isPagingEnabled = true
        headerCollectionView.showsHorizontalScrollIndicator = false
        headerCollectionView.dataSource = self
        headerCollectionView.delegate = self
        headerCollectionView.register(NavigationStepCell.self, forCellWithReuseIdentifier: NavigationStepCell.reuseIdentifier)

        headerCancelButton.setTitle("X", for: .normal)
        headerCancelButton.setTitleColor(AppColor.gray0, for: .normal)
        headerCancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)

        headerContentView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.equalTo(headerPageControl.snp.top).offset(-8)
        }

        headerCancelButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalTo(headerContentView)
            $0.width.height.equalTo(32)
        }

        headerCollectionView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.trailing.equalTo(headerCancelButton.snp.leading).offset(-8)
            $0.top.bottom.equalTo(headerContentView)
        }

        headerPageControl.currentPage = 0
        headerPageControl.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.4)
        headerPageControl.currentPageIndicatorTintColor = UIColor.white

        headerPageControl.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalTo(headerCancelButton.snp.leading).offset(-8)
            $0.bottom.equalTo(headerView.snp.bottom).offset(-6)
            $0.height.equalTo(12)
        }

        mapView.delegate = self
    }

    private func setupMapGestureRecognizer() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleMapPan(_:)))
        panGesture.delegate = self
        mapView.addGestureRecognizer(panGesture)
    }

    @objc private func handleMapPan(_ gesture: UIPanGestureRecognizer) {
        if gesture.state == .began || gesture.state == .changed {
            userDidDragMapSubject.send(())
            currentCameraMode = .browsing
            isProgrammaticMove = false
            updateRelocateButton(isTracking: false)
        }
    }

    private func addDestinationAnnotation() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(
            latitude: viewModel.destination.latitude,
            longitude: viewModel.destination.longitude
        )
        annotation.title = viewModel.destination.name
        annotation.subtitle = viewModel.destination.address
        destinationAnnotation = annotation
        mapView.addAnnotation(annotation)
    }

    override func bind() {
        super.bind()

        let cameraModeToggled = Empty<Bool, Never>(completeImmediately: false).eraseToAnyPublisher()
        let rerouteTapped = Empty<Void, Never>(completeImmediately: false).eraseToAnyPublisher()

        let input = NavigationViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            viewDidDisappear: viewDidDisappearSubject.eraseToAnyPublisher(),
            cancelButtonTapped: headerCancelButton.tapPublisher(),
            rerouteButtonTapped: rerouteTapped,
            rerouteConfirmed: rerouteConfirmedSubject.eraseToAnyPublisher(),
            toggleCameraMode: cameraModeToggled,
            userDidDragMap: userDidDragMapSubject.eraseToAnyPublisher(),
            relocateButtonTapped: relocateButton.tapPublisher(),
            mapCameraAltitudeChanged: mapCameraAltitudeChangedSubject.eraseToAnyPublisher()
        )

        let output = viewModel.transform(input: input)

        relocateButton.tapPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.currentCameraMode = .tracking
                self?.updateRelocateButton(isTracking: true)
            }
            .store(in: &cancellables)

        output.passedPath
            .receive(on: DispatchQueue.main)
            .sink { [weak self] coordinates in
                self?.updatePassedPath(coordinates)
            }
            .store(in: &cancellables)

        output.remainingPath
            .receive(on: DispatchQueue.main)
            .sink { [weak self] coordinates in
                self?.updateRemainingPath(coordinates)
            }
            .store(in: &cancellables)

        output.distanceToDestination
            .receive(on: DispatchQueue.main)
            .sink { [weak self] distance in
                self?.viewModelDistanceText = distance
                self?.bottomSheetView.update(
                    timeText: self?.viewModelTimeText ?? "",
                    distanceText: distance
                )
            }
            .store(in: &cancellables)

        output.estimatedTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] time in
                self?.viewModelTimeText = "약 \(time) 남음"
                self?.bottomSheetView.update(
                    timeText: self?.viewModelTimeText ?? "",
                    distanceText: self?.viewModelDistanceText ?? ""
                )
            }
            .store(in: &cancellables)

        output.currentStepIndex
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stepIndex in
                guard let self = self else { return }
                let headerIndex = min(stepIndex + 1, max(self.routeSteps.count - 1, 0))
                guard self.currentCameraMode == .tracking else { return }
                self.isHeaderSyncing = true
                self.headerPageControl.currentPage = headerIndex
                self.headerCollectionView.scrollToItem(
                    at: IndexPath(item: headerIndex, section: 0),
                    at: .centeredHorizontally,
                    animated: true
                )
            }
            .store(in: &cancellables)

        output.camera
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .throttle(for: .seconds(0.5), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] camera in
                guard let self = self else { return }
                guard self.currentCameraMode == .tracking else {
                    return
                }
                self.isProgrammaticMove = true
                self.mapView.setCamera(camera, animated: true)
            }
            .store(in: &cancellables)

        output.navigationState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleNavigationState(state)
            }
            .store(in: &cancellables)

        output.showArrivalAlert
            .receive(on: DispatchQueue.main)
            .sink { [weak self] storeName in
                self?.showAlert(
                    title: "도착",
                    message: "\(storeName)에 도착했습니다."
                )
            }
            .store(in: &cancellables)

        output.showRerouteAlert
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.showRerouteConfirmationAlert()
            }
            .store(in: &cancellables)

    }

    private func updateRelocateButton(isTracking: Bool) {
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let imageName = isTracking ? "location.fill" : "location"
        let image = UIImage(systemName: imageName, withConfiguration: config)
        relocateButton.setImage(image, for: .normal)
    }

    private func showRerouteConfirmationAlert() {
        let alert = UIAlertController(
            title: "경로 이탈",
            message: "경로를 벗어났습니다. 경로를 재탐색하시겠습니까?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "재탐색", style: .default) { [weak self] _ in
            self?.rerouteConfirmedSubject.send(())
        })

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        present(alert, animated: true)
    }

    private func updatePassedPath(_ coordinates: [CLLocationCoordinate2D]) {
        if let overlay = passedPathOverlay {
            mapView.removeOverlay(overlay)
        }

        guard coordinates.count >= 2 else { return }

        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        passedPathOverlay = polyline
        mapView.addOverlay(polyline, level: .aboveRoads)
    }

    private func updateRemainingPath(_ coordinates: [CLLocationCoordinate2D]) {
        if let overlay = remainingPathOverlay {
            mapView.removeOverlay(overlay)
        }

        guard coordinates.count >= 2 else { return }

        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        remainingPathOverlay = polyline
        mapView.addOverlay(polyline, level: .aboveRoads)
    }

    private func handleNavigationState(_ state: NavigationState) {
        switch state {
        case .idle:
            break
        case .navigating:
            break
        case .arrived:
            break
        case .offRoute:
            break
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateMapLayoutMargins()
        updateHeaderInsets()
    }

    private func updateMapLayoutMargins() {
        let topInset = headerView.frame.maxY + 8
        let bottomInset = view.bounds.height - bottomSheetView.frame.minY + 8
        mapView.layoutMargins = UIEdgeInsets(top: topInset, left: 0, bottom: bottomInset, right: 0)
    }

    private func updateHeaderInsets() {
        if headerCollectionView.contentInset != .zero {
            headerCollectionView.contentInset = .zero
            headerCollectionView.scrollIndicatorInsets = .zero
        }
    }
}

extension NavigationViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        routeSteps.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NavigationStepCell.reuseIdentifier, for: indexPath) as! NavigationStepCell
        cell.configure(with: routeSteps[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView === headerCollectionView else { return }
        if isHeaderSyncing { return }
        let index = Int(round(scrollView.contentOffset.x / max(scrollView.bounds.width, 1)))
        moveCameraToStep(at: index)
        headerPageControl.currentPage = index
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView === headerCollectionView else { return }
        isHeaderSyncing = false
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === headerCollectionView else { return }
        let index = Int(round(scrollView.contentOffset.x / max(scrollView.bounds.width, 1)))
        if index != headerPageControl.currentPage {
            headerPageControl.currentPage = index
        }
    }
}

private extension NavigationViewController {
    func setupHeaderSteps() {
        routeSteps = viewModel.routeSteps()
        let currentCoordinate = mapView.userLocation.location?.coordinate
        let destinationCoordinate = CLLocationCoordinate2D(
            latitude: viewModel.destination.latitude,
            longitude: viewModel.destination.longitude
        )
        let currentStep = NavigationRouteStep(
            id: currentLocationStepId,
            instruction: "현재 위치",
            distanceText: "0m",
            coordinate: currentCoordinate ?? destinationCoordinate,
            direction: .straight
        )
        routeSteps.insert(currentStep, at: 0)
        headerCollectionView.reloadData()
        headerPageControl.numberOfPages = routeSteps.count
        headerPageControl.isHidden = routeSteps.count <= 1
        moveCameraToStep(at: 0)
    }

    func moveCameraToStep(at index: Int) {
        guard index >= 0, index < routeSteps.count else { return }
        if index == 0, routeSteps[0].id == currentLocationStepId {
            currentCameraMode = .tracking
            updateRelocateButton(isTracking: true)
            updateStepPreviewAnnotation(for: index, coordinate: routeSteps[0].coordinate)
            return
        }
        currentCameraMode = .stepPreview
        updateRelocateButton(isTracking: false)
        let coordinate = routeSteps[index].coordinate
        updateStepPreviewAnnotation(for: index, coordinate: coordinate)
        let camera = MKMapCamera(
            lookingAtCenter: coordinate,
            fromDistance: 700,
            pitch: 45,
            heading: 0
        )
        isProgrammaticMove = true
        mapView.setCamera(camera, animated: true)
    }
}

private extension NavigationViewController {
    func updateStepPreviewAnnotation(for index: Int, coordinate: CLLocationCoordinate2D) {
        if let existing = stepPreviewAnnotation {
            mapView.removeAnnotation(existing)
            stepPreviewAnnotation = nil
        }

        guard index != 0 else { return }

        let annotation = NavigationStepAnnotation(
            coordinate: coordinate,
            title: routeSteps[index].instruction,
            direction: routeSteps[index].direction
        )
        stepPreviewAnnotation = annotation
        mapView.addAnnotation(annotation)
    }
}

extension NavigationViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let polyline = overlay as? MKPolyline else {
            return MKOverlayRenderer(overlay: overlay)
        }

        let renderer = MKPolylineRenderer(polyline: polyline)

        if overlay === passedPathOverlay {
            renderer.strokeColor = AppColor.gray60.withAlphaComponent(0.6)
            renderer.lineWidth = 6
            renderer.lineDashPattern = [2, 4]
        } else if overlay === remainingPathOverlay {
            renderer.strokeColor = AppColor.blackSprout
            renderer.lineWidth = 8
        }

        return renderer
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let stepAnnotation = annotation as? NavigationStepAnnotation {
            let identifier = "StepAnnotation"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: stepAnnotation, reuseIdentifier: identifier)
            view.annotation = stepAnnotation
            view.canShowCallout = false
            view.markerTintColor = AppColor.brightForsythia
            view.glyphImage = UIImage(systemName: stepAnnotation.direction.systemImageName)
            return view
        }

        guard annotation is MKPointAnnotation else { return nil }
        let identifier = "DestinationAnnotation"
        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        annotationView.annotation = annotation
        annotationView.canShowCallout = true
        annotationView.markerTintColor = AppColor.blackSprout
        annotationView.glyphImage = UIImage(systemName: "flag.fill")
        return annotationView
    }

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard let location = userLocation.location else { return }
        guard !routeSteps.isEmpty, routeSteps[0].id == currentLocationStepId else { return }

        let coordinate = location.coordinate
        guard CLLocationCoordinate2DIsValid(coordinate) else { return }

        if !hasAppliedInitialTrackingCamera, currentCameraMode == .tracking {
            hasAppliedInitialTrackingCamera = true
            let camera = MKMapCamera(
                lookingAtCenter: coordinate,
                fromDistance: 700,
                pitch: 45,
                heading: 0
            )
            isProgrammaticMove = true
            mapView.setCamera(camera, animated: false)
        }

        if routeSteps[0].coordinate.latitude != coordinate.latitude ||
            routeSteps[0].coordinate.longitude != coordinate.longitude {
            routeSteps[0] = NavigationRouteStep(
                id: currentLocationStepId,
                instruction: "현재 위치",
                distanceText: "0m",
                coordinate: coordinate,
                direction: .straight
            )
            headerCollectionView.reloadItems(at: [IndexPath(item: 0, section: 0)])
        }
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let altitude = mapView.camera.altitude
        mapCameraAltitudeChangedSubject.send(altitude)
        if isProgrammaticMove {
            isProgrammaticMove = false
        }
    }

    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        if isProgrammaticMove { return }
        let isUserGesture = mapView.gestureRecognizers?.contains { $0.state == .began || $0.state == .changed } ?? false
        if isUserGesture {
            currentCameraMode = .browsing
            updateRelocateButton(isTracking: false)
        }
    }
}

extension NavigationViewController {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
