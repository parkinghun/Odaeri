//
//  ChatImageGridView.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/11/26.
//

import UIKit
import SnapKit

final class ChatImageGridView: UIView {
    var onImageTapped: ((Int) -> Void)?

    private var imageViews: [UIImageView] = []
    private let containerStackView = UIStackView()
    private let leftStack = UIStackView()
    private let rightStack = UIStackView()

    private enum Layout {
        static let viewCornerRadius: CGFloat = 12
        static let borderWidth: CGFloat = 0.5
        static let spacing: CGFloat = 4
        static let singleImageMaxHeight: CGFloat = 300
        static let defaultAspectRatio: CGFloat = 4.0 / 3.0
        static let maxContentWidth: CGFloat = UIScreen.main.bounds.width * 0.75

        static var gridImageSize: CGFloat {
            return (maxContentWidth - spacing) / 2
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        createImageViewPool()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with urls: [String], aspectRatio: CGFloat? = nil) {
        guard !urls.isEmpty, urls.count <= 5 else { return }

        hideAllImageViews()

        for (index, url) in urls.enumerated() {
            let imageView = imageViews[index]
            imageView.isHidden = false
            imageView.setImage(
                url: url,
                placeholder: nil,
                animated: true,
                downsample: true
            )
        }

        layoutImages(count: urls.count, aspectRatio: aspectRatio)
    }

    private func setupUI() {
        clipsToBounds = true
        layer.cornerRadius = Layout.viewCornerRadius
        layer.borderWidth = Layout.borderWidth
        layer.borderColor = AppColor.gray30.cgColor
        backgroundColor = AppColor.gray15

        containerStackView.axis = .horizontal
        containerStackView.spacing = Layout.spacing
        containerStackView.distribution = .fillEqually

        leftStack.axis = .vertical
        leftStack.spacing = Layout.spacing
        leftStack.distribution = .fillEqually

        rightStack.axis = .vertical
        rightStack.spacing = Layout.spacing
        rightStack.distribution = .fillEqually

        addSubview(containerStackView)

        containerStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    private func createImageViewPool() {
        for _ in 0..<5 {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.backgroundColor = AppColor.gray15
            imageView.isUserInteractionEnabled = true
            imageView.isHidden = true

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleImageTap(_:)))
            imageView.addGestureRecognizer(tapGesture)

            imageViews.append(imageView)
        }
    }

    @objc private func handleImageTap(_ gesture: UITapGestureRecognizer) {
        guard let tappedView = gesture.view as? UIImageView,
              let index = imageViews.firstIndex(of: tappedView) else { return }
        onImageTapped?(index)
    }

    private func hideAllImageViews() {
        imageViews.forEach { $0.isHidden = true }

        leftStack.arrangedSubviews.forEach {
            leftStack.removeArrangedSubview($0)
        }
        rightStack.arrangedSubviews.forEach {
            rightStack.removeArrangedSubview($0)
        }

        containerStackView.arrangedSubviews.forEach {
            containerStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

    private func layoutImages(count: Int, aspectRatio: CGFloat?) {
        switch count {
        case 1:
            layoutSingleImage(aspectRatio: aspectRatio)
        case 2:
            layoutTwoImages()
        case 3:
            layoutThreeImages()
        case 4:
            layoutFourImages()
        case 5:
            layoutFiveImages()
        default:
            break
        }
    }

    private func layoutSingleImage(aspectRatio: CGFloat?) {
        containerStackView.axis = .vertical

        let imageView = imageViews[0]
        containerStackView.addArrangedSubview(imageView)

        let ratio = aspectRatio ?? Layout.defaultAspectRatio
        let calculatedHeight = Layout.maxContentWidth / ratio

        imageView.snp.remakeConstraints {
            $0.width.equalTo(containerStackView.snp.width)
            $0.height.equalTo(min(calculatedHeight, Layout.singleImageMaxHeight)).priority(.high)
        }
    }

    private func layoutTwoImages() {
        containerStackView.axis = .horizontal

        containerStackView.addArrangedSubview(imageViews[0])
        containerStackView.addArrangedSubview(imageViews[1])

        containerStackView.snp.remakeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(Layout.gridImageSize).priority(.high)
        }
    }

    private func layoutThreeImages() {
        containerStackView.axis = .horizontal

        leftStack.addArrangedSubview(imageViews[0])

        rightStack.addArrangedSubview(imageViews[1])
        rightStack.addArrangedSubview(imageViews[2])

        containerStackView.addArrangedSubview(leftStack)
        containerStackView.addArrangedSubview(rightStack)

        let totalHeight = Layout.gridImageSize * 2 + Layout.spacing

        containerStackView.snp.remakeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(totalHeight).priority(.high)
        }
    }

    private func layoutFourImages() {
        containerStackView.axis = .horizontal

        leftStack.addArrangedSubview(imageViews[0])
        leftStack.addArrangedSubview(imageViews[1])

        rightStack.addArrangedSubview(imageViews[2])
        rightStack.addArrangedSubview(imageViews[3])

        containerStackView.addArrangedSubview(leftStack)
        containerStackView.addArrangedSubview(rightStack)

        let totalHeight = Layout.gridImageSize * 2 + Layout.spacing

        containerStackView.snp.remakeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(totalHeight).priority(.high)
        }
    }

    private func layoutFiveImages() {
        containerStackView.axis = .horizontal

        leftStack.addArrangedSubview(imageViews[0])
        leftStack.addArrangedSubview(imageViews[1])

        rightStack.addArrangedSubview(imageViews[2])
        rightStack.addArrangedSubview(imageViews[3])
        rightStack.addArrangedSubview(imageViews[4])

        containerStackView.addArrangedSubview(leftStack)
        containerStackView.addArrangedSubview(rightStack)

        let totalHeight = Layout.gridImageSize * 2 + Layout.spacing

        containerStackView.snp.remakeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(totalHeight).priority(.high)
        }
    }

    static func calculateHeight(for imageCount: Int, aspectRatio: CGFloat? = nil) -> CGFloat {
        switch imageCount {
        case 1:
            let ratio = aspectRatio ?? Layout.defaultAspectRatio
            let calculatedHeight = Layout.maxContentWidth / ratio
            return min(calculatedHeight, Layout.singleImageMaxHeight)
        case 2:
            return Layout.gridImageSize
        case 3, 4, 5:
            return Layout.gridImageSize * 2 + Layout.spacing
        default:
            return 0
        }
    }
}
