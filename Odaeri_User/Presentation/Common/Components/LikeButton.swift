//
//  LikeButton.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/1/26.
//

import UIKit
import Combine

final class LikeButton: UIButton {
    struct TapEvent {
        let storeId: String
        let newState: Bool
    }

    let tapPublisher = PassthroughSubject<TapEvent, Never>()
    private var cancellables = Set<AnyCancellable>()

    var storeId: String = ""
    @Published var isPicked: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupButton() {
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    private func bind() {
        $isPicked
            .receive(on: RunLoop.main)
            .sink { [weak self] isPicked in
                self?.updateUI(isPicked: isPicked)
            }
            .store(in: &cancellables)
    }

    private func updateUI(isPicked: Bool) {
        let image = isPicked ? AppImage.likeFill : AppImage.likeEmpty
        let color = isPicked ? AppColor.blackSprout : AppColor.gray45
        setImage(image, for: .normal)
        tintColor = color

        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseInOut) {
            self.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        } completion: { _ in
            UIView.animate(withDuration: 0.15) {
                self.transform = .identity
            }
        }
    }

    @objc private func handleTap() {
        isPicked.toggle()
        tapPublisher.send(TapEvent(storeId: storeId, newState: isPicked))
    }

    func configure(storeId: String, isPicked: Bool) {
        self.storeId = storeId
        self.isPicked = isPicked
    }

    func revert() {
        isPicked.toggle()
    }
}
