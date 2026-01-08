//
//  AppFont.swift
//  Odaeri
//
//  Created by 박성훈 on 12/15/25.
//

import UIKit

enum AppFont {
    static let title1 = FontFamily.Pretendard.bold.of(size: 20)
    static let body1Bold = FontFamily.Pretendard.bold.of(size: 16)
    static let body1 = FontFamily.Pretendard.medium.of(size: 16)
    static let body1Regular = FontFamily.Pretendard.regular.of(size: 16)
    static let body2 = FontFamily.Pretendard.medium.of(size: 14)
    static let body2Regular = FontFamily.Pretendard.regular.of(size: 14)
    static let body2Bold = FontFamily.Pretendard.bold.of(size: 14)
    static let body3 = FontFamily.Pretendard.medium.of(size: 13)
    static let body3Bold = FontFamily.Pretendard.bold.of(size: 13)
    static let caption = FontFamily.Pretendard.semiBold.of(size: 12)
    static let caption1 = FontFamily.Pretendard.regular.of(size: 12)
    static let caption2 = FontFamily.Pretendard.regular.of(size: 10)
    static let caption2Medium = FontFamily.Pretendard.medium.of(size: 10)
    static let caption2SemiBold = FontFamily.Pretendard.semiBold.of(size: 10)
    static let caption3 = FontFamily.Pretendard.regular.of(size: 8)
    
    static let brandTitle1 = FontFamily.Jalnan.gothic.of(size: 24)
    static let brandBody1 = FontFamily.Jalnan.gothic.of(size: 20)
    static let brandCaption1 = FontFamily.Jalnan.gothic.of(size: 14)
}

final class FontPreviewView: UIView {
    private let stackView = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        configureFonts()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        backgroundColor = .white
        
        stackView.axis = .vertical
        stackView.spacing = 12
        
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }
    
    private func configureFonts() {
        addLabel(text: "Title1 - Pretendard Bold 20", font: AppFont.title1)
        addLabel(text: "Body1 - Pretendard Medium 16", font: AppFont.body1)
        addLabel(text: "Body2 - Pretendard Medium 14", font: AppFont.body2)
        addLabel(text: "Body3 - Pretendard Medium 13", font: AppFont.body3)
        addLabel(text: "Caption1 - Pretendard Regular 12", font: AppFont.caption1)
        addLabel(text: "Caption2 - Pretendard Regular 10", font: AppFont.caption2)
        addLabel(text: "Caption3 - Pretendard Regular 8", font: AppFont.caption3)
        
        addLabel(text: "Brand Title - Jalnan 24", font: AppFont.brandTitle1)
        addLabel(text: "Brand Body - Jalnan 20", font: AppFont.brandBody1)
        addLabel(text: "Brand Body - Jalnan 14", font: AppFont.brandCaption1)
    }
    
    private func addLabel(text: String, font: UIFont) {
        let label = UILabel()
        label.text = text
        label.font = font
        label.numberOfLines = 0
        stackView.addArrangedSubview(label)
    }
}

