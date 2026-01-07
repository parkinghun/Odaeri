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

    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()
    private let viewDidDisappearSubject = PassthroughSubject<Void, Never>()
    private var is3DCameraMode = true

    private lazy var mapView: MKMapView = {
        let map = MKMapView()
        map.mapType = .standard
        map.showsUserLocation = true
        map.isRotateEnabled = true
        map.isPitchEnabled = true
        return map
    }()

    private let infoContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.gray0
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        return view
    }()

    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.title1
        label.textColor = AppColor.blackSprout
        label.textAlignment = .center
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2
        label.textColor = AppColor.gray75
        label.textAlignment = .center
        return label
    }()

    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("취소", for: .normal)
        button.setTitleColor(AppColor.gray0, for: .normal)
        button.titleLabel?.font = AppFont.body1
        button.backgroundColor = AppColor.gray75
        button.layer.cornerRadius = 12
        return button
    }()

    private let rerouteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("재탐색", for: .normal)
        button.setTitleColor(AppColor.gray0, for: .normal)
        button.titleLabel?.font = AppFont.body1
        button.backgroundColor = AppColor.blackSprout
        button.layer.cornerRadius = 12
        return button
    }()

    private let cameraModeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("2D", for: .normal)
        button.setTitleColor(AppColor.gray100, for: .normal)
        button.titleLabel?.font = AppFont.body2
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

    override func viewDidLoad() {
        super.viewDidLoad()
        viewDidLoadSubject.send(())
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewDidDisappearSubject.send(())
    }

    override func setupUI() {
        super.setupUI()

        view.addSubview(mapView)
        view.addSubview(infoContainerView)
        view.addSubview(cancelButton)
        view.addSubview(rerouteButton)
        view.addSubview(cameraModeButton)

        infoContainerView.addSubview(distanceLabel)
        infoContainerView.addSubview(timeLabel)

        mapView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        infoContainerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(80)
        }

        distanceLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.centerX.equalToSuperview()
        }

        timeLabel.snp.makeConstraints {
            $0.top.equalTo(distanceLabel.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
        }

        cancelButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
            $0.width.equalTo(100)
            $0.height.equalTo(48)
        }

        rerouteButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
            $0.width.equalTo(100)
            $0.height.equalTo(48)
        }

        cameraModeButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalTo(rerouteButton.snp.top).offset(-12)
            $0.width.equalTo(60)
            $0.height.equalTo(44)
        }

        mapView.delegate = self
    }

    override func bind() {
        super.bind()

        let cameraModeToggled = cameraModeButton.tapPublisher()
            .map { [weak self] _ -> Bool in
                guard let self = self else { return true }
                self.is3DCameraMode.toggle()
                let newTitle = self.is3DCameraMode ? "2D" : "3D"
                self.cameraModeButton.setTitle(newTitle, for: .normal)
                return self.is3DCameraMode
            }
            .eraseToAnyPublisher()

        let input = NavigationViewModel.Input(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            viewDidDisappear: viewDidDisappearSubject.eraseToAnyPublisher(),
            cancelButtonTapped: cancelButton.tapPublisher(),
            rerouteButtonTapped: rerouteButton.tapPublisher(),
            toggleCameraMode: cameraModeToggled
        )

        let output = viewModel.transform(input: input)

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
                self?.distanceLabel.text = distance
            }
            .store(in: &cancellables)

        output.estimatedTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] time in
                self?.timeLabel.text = "약 \(time) 남음"
            }
            .store(in: &cancellables)

        output.camera
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] camera in
                self?.mapView.setCamera(camera, animated: true)
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

    private func showRerouteConfirmationAlert() {
        let alert = UIAlertController(
            title: "경로 이탈",
            message: "경로를 벗어났습니다. 경로를 재탐색하시겠습니까?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "재탐색", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.viewModel.coordinator?.requestReroute(to: self.viewModel.destination)
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
            rerouteButton.isHidden = true
        case .navigating:
            rerouteButton.isHidden = true
        case .arrived:
            rerouteButton.isHidden = true
        case .offRoute:
            rerouteButton.isHidden = false
        }
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
}
