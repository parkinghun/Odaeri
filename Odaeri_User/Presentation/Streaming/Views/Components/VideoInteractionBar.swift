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
    let scriptButtonTappedPublisher: AnyPublisher<Void, Never>

    private let likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        return button
    }()

    private let likeCountLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.body2
        label.textColor = AppColor.gray75
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "square.and.arrow.up")
        config.imagePadding = 4
        config.baseForegroundColor = AppColor.gray75
        config.title = "공유"
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = AppFont.body2
            return outgoing
        }
        button.configuration = config
        return button
    }()

    private let scriptButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "text.alignleft")
        config.imagePadding = 4
        config.baseForegroundColor = AppColor.gray75
        config.title = "스크립트"
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = AppFont.body2
            return outgoing
        }
        button.configuration = config
        return button
    }()

    private let likesStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let buttonsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 16
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override init(frame: CGRect) {
        let likeButtonSubject = PassthroughSubject<Void, Never>()
        let shareButtonSubject = PassthroughSubject<Void, Never>()
        let scriptButtonSubject = PassthroughSubject<Void, Never>()

        likeButtonTappedPublisher = likeButtonSubject.eraseToAnyPublisher()
        shareButtonTappedPublisher = shareButtonSubject.eraseToAnyPublisher()
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

        likesStackView.addArrangedSubview(likeButton)
        likesStackView.addArrangedSubview(likeCountLabel)

        buttonsStackView.addArrangedSubview(shareButton)
        buttonsStackView.addArrangedSubview(scriptButton)

        addSubview(likesStackView)
        addSubview(buttonsStackView)

        NSLayoutConstraint.activate([
            likesStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            likesStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            likesStackView.topAnchor.constraint(equalTo: topAnchor),
            likesStackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            buttonsStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            buttonsStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            buttonsStackView.topAnchor.constraint(equalTo: topAnchor),
            buttonsStackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            likeButton.widthAnchor.constraint(equalToConstant: 24),
            likeButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    func configure(isLiked: Bool, likeCount: Int, animated: Bool = false) {
        let image = isLiked ? AppImage.likeFill : AppImage.likeEmpty
        let color = isLiked ? AppColor.blackSprout : AppColor.gray75
        likeButton.setImage(image, for: .normal)
        likeButton.tintColor = color
        likeCountLabel.text = "\(likeCount)"

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
}
