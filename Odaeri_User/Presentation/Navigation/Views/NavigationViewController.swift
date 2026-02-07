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

    private var originalRouteOverlay: MKPolyline?
    private var remainingPathOverlay: MKPolyline?
    private var startAnnotation: MKPointAnnotation?
    private var destinationAnnotation: MKPointAnnotation?
    private var stepAnnotations: [NavigationStepAnnotation] = []
    private var routeSteps: [NavigationRouteStep] = []
    private var headerSteps: [NavigationRouteStep] = []
    private var currentCameraMode: CameraMode = .tracking
    private var isProgrammaticMove: Bool = false
    private let currentLocationStepId = "current-location-step"
    private var hasAppliedInitialTrackingCamera = false
    private var isHeaderSyncing = false
    private var rerouteAlertView: NavigationRerouteAlertView?
    private var rerouteCountdownTimer: Timer?
    private var rerouteCountdownSeconds = 10
    private var isRerouteAlertPresented = false

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
        addOriginalRouteOverlay()
        addStartAnnotation()
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
        if gesture.state == .began {
            print("[ViewController] Pan gesture began - stopping camera animations")

            mapView.layer.removeAllAnimations()

            userDidDragMapSubject.send(())
            currentCameraMode = .browsing
            isProgrammaticMove = false
            updateRelocateButton(isTracking: false)
        } else if gesture.state == .changed {
            currentCameraMode = .browsing
            isProgrammaticMove = false
        }
    }

    private func addOriginalRouteOverlay() {
        let polyline = viewModel.route.polyline
        originalRouteOverlay = polyline
        mapView.addOverlay(polyline, level: .aboveRoads)
        print("[OriginalRoute] Full route overlay added (never changes)")
    }

    private func addStartAnnotation() {
        guard let startCoordinate = viewModel.route.polyline.firstCoordinate else { return }

        let annotation = MKPointAnnotation()
        annotation.coordinate = startCoordinate
        annotation.title = "출발"
        startAnnotation = annotation
        mapView.addAnnotation(annotation)
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
                let headerIndex = min(stepIndex + 1, max(self.headerSteps.count - 1, 0))

                print("[StepSync] Current step: \(stepIndex) → header: \(headerIndex), cameraMode: \(self.currentCameraMode)")

                self.headerPageControl.currentPage = headerIndex

                if self.currentCameraMode == .tracking {
                    self.isHeaderSyncing = true
                    self.headerCollectionView.scrollToItem(
                        at: IndexPath(item: headerIndex, section: 0),
                        at: .centeredHorizontally,
                        animated: true
                    )
                    print("[StepSync] Header auto-scrolled to \(headerIndex) (tracking mode)")
                } else {
                    print("[StepSync] Header auto-scroll skipped (browsing/preview mode)")
                }
            }
            .store(in: &cancellables)

        output.camera
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .throttle(for: .milliseconds(200), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] camera in
                guard let self = self else { return }
                guard self.currentCameraMode == .tracking else {
                    return
                }
                self.isProgrammaticMove = true
                self.mapView.setCamera(camera, animated: false)
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
        guard !isRerouteAlertPresented else { return }
        isRerouteAlertPresented = true
        rerouteCountdownSeconds = 10

        let alertView = NavigationRerouteAlertView()
        alertView.updateCountdown(rerouteCountdownSeconds)
        alertView.onConfirm = { [weak self] in
            self?.rerouteConfirmedSubject.send(())
            self?.dismissRerouteAlert()
        }
        alertView.onCancel = { [weak self] in
            self?.dismissRerouteAlert()
        }

        rerouteAlertView = alertView
        view.addSubview(alertView)
        alertView.snp.makeConstraints { $0.edges.equalToSuperview() }

        startRerouteCountdown()
    }

    private func startRerouteCountdown() {
        rerouteCountdownTimer?.invalidate()
        rerouteCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else { return }
            rerouteCountdownSeconds -= 1
            rerouteAlertView?.updateCountdown(rerouteCountdownSeconds)

            if rerouteCountdownSeconds <= 0 {
                timer.invalidate()
                dismissRerouteAlert()
            }
        }
    }

    private func dismissRerouteAlert() {
        rerouteCountdownTimer?.invalidate()
        rerouteCountdownTimer = nil
        rerouteAlertView?.removeFromSuperview()
        rerouteAlertView = nil
        isRerouteAlertPresented = false
    }

    private func updateRemainingPath(_ coordinates: [CLLocationCoordinate2D]) {
        if let overlay = remainingPathOverlay {
            mapView.removeOverlay(overlay)
        }

        print("[RemainingPath] Received \(coordinates.count) coordinates")
        guard coordinates.count >= 2 else {
            print("[RemainingPath] Not enough coordinates to draw polyline")
            return
        }

        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        remainingPathOverlay = polyline
        mapView.addOverlay(polyline, level: .aboveLabels)
        print("[RemainingPath] Polyline added to map with .aboveLabels level")
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

private final class NavigationRerouteAlertView: UIView {
    var onConfirm: (() -> Void)?
    var onCancel: (() -> Void)?

    private let dimView = UIView()
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let countdownBadge = UIView()
    private let countdownLabel = UILabel()
    private let buttonStack = UIStackView()
    private let confirmButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateCountdown(_ seconds: Int) {
        let value = max(0, seconds)
        countdownLabel.text = "\(value)"
        messageLabel.text = "\(value)초 후 자동으로 기존 경로 안내를 계속합니다."
    }

    private func setupUI() {
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.35)

        containerView.backgroundColor = AppColor.gray0
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.08
        containerView.layer.shadowOffset = CGSize(width: 0, height: 6)
        containerView.layer.shadowRadius = 16

        titleLabel.text = "경로 이탈"
        titleLabel.font = AppFont.body1Bold
        titleLabel.textColor = AppColor.blackSprout
        titleLabel.textAlignment = .center

        messageLabel.font = AppFont.body2Bold
        messageLabel.textColor = AppColor.gray75
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center

        countdownBadge.backgroundColor = AppColor.brightSprout
        countdownBadge.layer.cornerRadius = 18

        countdownLabel.font = AppFont.body1Bold
        countdownLabel.textColor = AppColor.blackSprout
        countdownLabel.textAlignment = .center

        confirmButton.setTitle("재탐색", for: .normal)
        confirmButton.setTitleColor(AppColor.gray0, for: .normal)
        confirmButton.titleLabel?.font = AppFont.body1Bold
        confirmButton.backgroundColor = AppColor.blackSprout
        confirmButton.layer.cornerRadius = 10
        confirmButton.addTarget(self, action: #selector(handleConfirm), for: .touchUpInside)

        cancelButton.setTitle("계속 진행", for: .normal)
        cancelButton.setTitleColor(AppColor.blackSprout, for: .normal)
        cancelButton.titleLabel?.font = AppFont.body1Bold
        cancelButton.backgroundColor = AppColor.gray15
        cancelButton.layer.cornerRadius = 10
        cancelButton.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)

        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually

        addSubview(dimView)
        addSubview(containerView)

        containerView.addSubview(titleLabel)
        containerView.addSubview(messageLabel)
        containerView.addSubview(countdownBadge)
        countdownBadge.addSubview(countdownLabel)
        containerView.addSubview(buttonStack)
        buttonStack.addArrangedSubview(cancelButton)
        buttonStack.addArrangedSubview(confirmButton)

        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }

        containerView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(32)
        }

        countdownBadge.snp.makeConstraints {
            $0.top.equalToSuperview().inset(24)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(36)
        }

        countdownLabel.snp.makeConstraints { $0.edges.equalToSuperview() }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(countdownBadge.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        messageLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        buttonStack.snp.makeConstraints {
            $0.top.equalTo(messageLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
            $0.bottom.equalToSuperview().inset(20)
        }
    }

    @objc private func handleConfirm() {
        onConfirm?()
    }

    @objc private func handleCancel() {
        onCancel?()
    }
}

extension NavigationViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        headerSteps.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NavigationStepCell.reuseIdentifier, for: indexPath) as! NavigationStepCell
        cell.configure(with: headerSteps[indexPath.item])
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
        headerSteps = [currentStep] + routeSteps

        print("[HeaderSetup] Total headerSteps: \(headerSteps.count)")
        print("[HeaderSetup] headerSteps[0]: \(headerSteps[0].instruction)")
        if routeSteps.count > 0 {
            print("[HeaderSetup] headerSteps[1] (routeSteps[0]): \(headerSteps[1].instruction)")
        }

        headerCollectionView.reloadData()
        headerPageControl.numberOfPages = headerSteps.count
        headerPageControl.isHidden = headerSteps.count <= 1
        updateStepAnnotations()
        moveCameraToStep(at: 0)
    }

    func moveCameraToStep(at index: Int) {
        guard index >= 0, index < headerSteps.count else { return }
        if index == 0, headerSteps[0].id == currentLocationStepId {
            currentCameraMode = .tracking
            updateRelocateButton(isTracking: true)
            return
        }
        let routeIndex = index - 1
        guard routeIndex >= 0, routeIndex < routeSteps.count else { return }
        currentCameraMode = .stepPreview
        updateRelocateButton(isTracking: false)
        userDidDragMapSubject.send()
        let coordinate = routeSteps[routeIndex].coordinate
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
    func updateStepAnnotations() {
        if !stepAnnotations.isEmpty {
            mapView.removeAnnotations(stepAnnotations)
            stepAnnotations.removeAll()
        }

        guard !routeSteps.isEmpty else { return }

        stepAnnotations = routeSteps.map { step in
            NavigationStepAnnotation(
                coordinate: step.coordinate,
                title: step.instruction,
                direction: step.direction
            )
        }
        mapView.addAnnotations(stepAnnotations)
    }
}

extension NavigationViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let polyline = overlay as? MKPolyline else {
            return MKOverlayRenderer(overlay: overlay)
        }

        let renderer = MKPolylineRenderer(polyline: polyline)

        if overlay === originalRouteOverlay {
            renderer.strokeColor = AppColor.gray60
            renderer.lineWidth = 8
            renderer.lineCap = .round
            renderer.lineJoin = .round
        } else if overlay === remainingPathOverlay {
            renderer.strokeColor = AppColor.blackSprout
            renderer.lineWidth = 8
            renderer.lineCap = .round
            renderer.lineJoin = .round
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

        if annotation === startAnnotation {
            let identifier = "StartAnnotation"
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView.annotation = annotation
            annotationView.canShowCallout = true
            annotationView.markerTintColor = AppColor.deepSprout
            annotationView.glyphImage = UIImage(systemName: "figure.walk")
            return annotationView
        }

        if annotation === destinationAnnotation {
            let identifier = "DestinationAnnotation"
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView.annotation = annotation
            annotationView.canShowCallout = true
            annotationView.markerTintColor = AppColor.blackSprout
            annotationView.glyphImage = UIImage(systemName: "flag.fill")
            return annotationView
        }

        return nil
    }

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard let location = userLocation.location else { return }
        guard !headerSteps.isEmpty, headerSteps[0].id == currentLocationStepId else { return }

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

        if headerSteps[0].coordinate.latitude != coordinate.latitude ||
            headerSteps[0].coordinate.longitude != coordinate.longitude {
            headerSteps[0] = NavigationRouteStep(
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
            print("[ViewController] User gesture detected in regionWillChange - stopping animations")

            mapView.layer.removeAllAnimations()

            userDidDragMapSubject.send(())
            currentCameraMode = .browsing
            isProgrammaticMove = false
            updateRelocateButton(isTracking: false)
        }
    }
}

extension NavigationViewController {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

private extension MKPolyline {
    var firstCoordinate: CLLocationCoordinate2D? {
        guard pointCount > 0 else { return nil }
        var coordinate = CLLocationCoordinate2D()
        getCoordinates(&coordinate, range: NSRange(location: 0, length: 1))
        return coordinate
    }

    var lastCoordinate: CLLocationCoordinate2D? {
        guard pointCount > 0 else { return nil }
        var coordinate = CLLocationCoordinate2D()
        getCoordinates(&coordinate, range: NSRange(location: pointCount - 1, length: 1))
        return coordinate
    }
}
