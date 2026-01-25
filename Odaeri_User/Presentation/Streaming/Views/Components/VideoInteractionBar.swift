//
//  VideoInteractionBar.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/25/26.
//

import UIKit
import Combine

final class VideoInteractionBar: UIView {
    private var cancellables = Set<AnyCancellable>()

    let likeButtonTappedPublisher: AnyPublisher<Void, Never>
    let shareButtonTappedPublisher: AnyPublisher<Void, Never>
    let saveButtonTappedPublisher: AnyPublisher<Void, Never>
    let scriptButtonTappedPublisher: AnyPublisher<Void, Never>

    private let likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        var config = UIButton.Configuration.plain()
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        config.image = AppImage.likeEmpty.withConfiguration(imageConfig)
        config.imagePadding = 4
        config.baseForegroundColor = AppColor.gray75
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        config.background.backgroundColor = AppColor.gray15
        config.background.cornerRadius = 8
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = AppFont.body3
            return outgoing
        }
        button.configuration = config
        return button
    }()

    private let shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        var config = UIButton.Configuration.plain()
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        config.image = AppImage.share.withConfiguration(imageConfig)
        config.imagePadding = 4
        config.baseForegroundColor = AppColor.gray75
        config.title = "공유"
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        config.background.backgroundColor = AppColor.gray15
        config.background.cornerRadius = 8
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = AppFont.body3
            return outgoing
        }
        button.configuration = config
        return button
    }()

    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        var config = UIButton.Configuration.plain()
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        config.image = AppImage.save.withConfiguration(imageConfig)
        config.imagePadding = 4
        config.baseForegroundColor = AppColor.gray75
        config.title = "저장"
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        config.background.backgroundColor = AppColor.gray15
        config.background.cornerRadius = 8
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = AppFont.body3
            return outgoing
        }
        button.configuration = config
        return button
    }()

    private let scriptButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        var config = UIButton.Configuration.plain()
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        config.image = AppImage.script.withConfiguration(imageConfig)
        config.imagePadding = 4
        config.baseForegroundColor = AppColor.gray75
        config.title = "스크립트"
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        config.background.backgroundColor = AppColor.gray15
        config.background.cornerRadius = 8
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = AppFont.body3
            return outgoing
        }
        button.configuration = config
        return button
    }()

    private let buttonsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillProportionally
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let emptyView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }()

    override init(frame: CGRect) {
        let likeButtonSubject = PassthroughSubject<Void, Never>()
        let shareButtonSubject = PassthroughSubject<Void, Never>()
        let saveButtonSubject = PassthroughSubject<Void, Never>()
        let scriptButtonSubject = PassthroughSubject<Void, Never>()

        likeButtonTappedPublisher = likeButtonSubject.eraseToAnyPublisher()
        shareButtonTappedPublisher = shareButtonSubject.eraseToAnyPublisher()
        saveButtonTappedPublisher = saveButtonSubject.eraseToAnyPublisher()
        scriptButtonTappedPublisher = scriptButtonSubject.eraseToAnyPublisher()

        super.init(frame: frame)
        setupViews()

        likeButton.tapPublisher()
            .sink { _ in
                print("[VideoInteractionBar] Like button tapped")
                likeButtonSubject.send(())
            }
            .store(in: &cancellables)

        shareButton.tapPublisher()
            .sink { _ in
                print("[VideoInteractionBar] Share button tapped")
                shareButtonSubject.send(())
            }
            .store(in: &cancellables)

        saveButton.tapPublisher()
            .sink { _ in
                print("[VideoInteractionBar] Save button tapped")
                saveButtonSubject.send(())
            }
            .store(in: &cancellables)

        scriptButton.tapPublisher()
            .sink { _ in
                print("[VideoInteractionBar] Script button tapped")
                scriptButtonSubject.send(())
            }
            .store(in: &cancellables)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        isUserInteractionEnabled = true

        likeButton.setContentHuggingPriority(.required, for: .horizontal)
        likeButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        shareButton.setContentHuggingPriority(.required, for: .horizontal)
        shareButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        saveButton.setContentHuggingPriority(.required, for: .horizontal)
        saveButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        scriptButton.setContentHuggingPriority(.required, for: .horizontal)
        scriptButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        buttonsStackView.addArrangedSubview(likeButton)
        buttonsStackView.addArrangedSubview(shareButton)
        buttonsStackView.addArrangedSubview(saveButton)
        buttonsStackView.addArrangedSubview(scriptButton)
        buttonsStackView.addArrangedSubview(emptyView)

        addSubview(buttonsStackView)

        let saveButtonWidthConstraint = saveButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 70)
        saveButtonWidthConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            buttonsStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            buttonsStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            buttonsStackView.topAnchor.constraint(equalTo: topAnchor),
            buttonsStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            saveButtonWidthConstraint
        ])
    }

    func configure(isLiked: Bool, likeCount: Int, animated: Bool = false) {
        var config = likeButton.configuration
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        let image = isLiked ? AppImage.likeFill : AppImage.likeEmpty
        let color = isLiked ? AppColor.blackSprout : AppColor.gray75

        config?.image = image.withConfiguration(imageConfig)
        config?.baseForegroundColor = color
        config?.title = "\(likeCount)"
        likeButton.configuration = config

        if animated {
            UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseInOut) {
                self.likeButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            } completion: { _ in
                UIView.animate(withDuration: 0.15) {
                    self.likeButton.transform = .identity
                }
            }
        }
    }

    func updateSaveButton(isSaved: Bool) {
        var config = saveButton.configuration
        config?.title = isSaved ? "저장됨" : "저장"
        saveButton.configuration = config
    }

    func updateScriptButton(hasScript: Bool) {
        scriptButton.isEnabled = hasScript
        var config = scriptButton.configuration
        config?.baseForegroundColor = hasScript ? AppColor.gray75 : AppColor.gray45
        scriptButton.configuration = config
    }
}
