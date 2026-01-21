//
//  PlayerControlView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/19/26.
//

import UIKit
import AVFoundation
import Combine
import SnapKit

final class PlayerControlView: UIView {
    private let playPauseButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = AppColor.gray0
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .regular)
        button.setImage(UIImage(systemName: "play.fill", withConfiguration: config), for: .normal)
        return button
    }()

    private let fullscreenButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = AppColor.gray0
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        button.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right", withConfiguration: config), for: .normal)
        return button
    }()

    private let settingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = AppColor.gray0
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        button.setImage(UIImage(systemName: "gearshape.fill", withConfiguration: config), for: .normal)
        return button
    }()

    private let progressSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.minimumTrackTintColor = AppColor.brightForsythia
        slider.maximumTrackTintColor = AppColor.gray45
        slider.setThumbImage(createThumbImage(), for: .normal)
        return slider
    }()

    private let currentTimeLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = AppColor.gray0
        label.text = "0:00"
        return label
    }()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption1
        label.textColor = AppColor.gray0
        label.text = "0:00"
        return label
    }()

    private var cancellables = Set<AnyCancellable>()
    private let seekSubject = PassthroughSubject<Float, Never>()

    let playPauseTappedPublisher: AnyPublisher<Void, Never>
    let settingsTappedPublisher: AnyPublisher<Void, Never>
    let fullscreenTappedPublisher: AnyPublisher<Void, Never>
    let seekToProgressPublisher: AnyPublisher<Float, Never>

    override init(frame: CGRect) {
        playPauseTappedPublisher = playPauseButton.tapPublisher().eraseToAnyPublisher()
        settingsTappedPublisher = settingsButton.tapPublisher().eraseToAnyPublisher()
        fullscreenTappedPublisher = fullscreenButton.tapPublisher().eraseToAnyPublisher()
        seekToProgressPublisher = seekSubject.eraseToAnyPublisher()

        super.init(frame: frame)
        setupUI()
        bindSlider()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.6)

        addSubview(playPauseButton)
        addSubview(fullscreenButton)
        addSubview(settingsButton)
        addSubview(currentTimeLabel)
        addSubview(durationLabel)
        addSubview(progressSlider)

        playPauseButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().inset(20)
            make.width.height.equalTo(44)
        }

        settingsButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(20)
            make.width.height.equalTo(44)
        }

        fullscreenButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(settingsButton.snp.leading).offset(-8)
            make.width.height.equalTo(44)
        }

        currentTimeLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(playPauseButton.snp.trailing).offset(12)
        }

        durationLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(fullscreenButton.snp.leading).offset(-12)
        }

        progressSlider.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(currentTimeLabel.snp.trailing).offset(12)
            make.trailing.equalTo(durationLabel.snp.leading).offset(-12)
        }
    }

    private func bindSlider() {
        progressSlider.tapPublisher(for: [.touchUpInside, .touchUpOutside])
            .sink { [weak self] in
                guard let self = self else { return }
                self.seekSubject.send(self.progressSlider.value)
            }
            .store(in: &cancellables)
    }

    func updatePlayPauseButton(isPlaying: Bool) {
        let config = UIImage.SymbolConfiguration(pointSize: 32, weight: .regular)
        let imageName = isPlaying ? "pause.fill" : "play.fill"
        playPauseButton.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
    }

    func updateProgress(_ progress: Float, animated: Bool = true) {
        progressSlider.setValue(progress, animated: animated)
    }

    func updateCurrentTimeText(_ text: String) {
        currentTimeLabel.text = text
    }

    func updateDurationText(_ text: String) {
        durationLabel.text = text
    }

    private static func createThumbImage() -> UIImage? {
        let size = CGSize(width: 14, height: 14)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            AppColor.gray0.setFill()
            context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
        }
    }
}
