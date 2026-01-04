//
//  FilterToggleButton.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/2/26.
//

import UIKit
import Combine

final class FilterToggleButton: UIButton {
    private let tapSubject = PassthroughSubject<Bool, Never>()
    var tapPublisher: AnyPublisher<Bool, Never> {
        tapSubject.eraseToAnyPublisher()
    }
    
    private let title: String
    
    init(title: String) {
        self.title = title
        super.init(frame: .zero)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupButton() {
        var config = UIButton.Configuration.plain()
        
        let resizedImage = AppImage.list
            .resize(to: CGSize(width: 16, height: 16))
            .withRenderingMode(.alwaysTemplate)

        config.image = resizedImage
        config.imagePlacement = .leading
        config.imagePadding = 4
        
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        
        self.configuration = config
        
        self.configurationUpdateHandler = { [weak self] button in
            guard let self = self,
                  var updatedConfig = button.configuration else { return }
            
            let isSelected = button.isSelected
            
            updatedConfig.image = isSelected ? AppImage.checkmarkFill : AppImage.checkmarkEmpty
            
            var titleContainer = AttributeContainer()
            let tintColor = isSelected ? AppColor.blackSprout : AppColor.brightSprout
            titleContainer.font = AppFont.caption
            titleContainer.foregroundColor = tintColor
            updatedConfig.attributedTitle = AttributedString(self.title, attributes: titleContainer)
            
            updatedConfig.background.backgroundColor = .clear
            // 상태에 따른 이미지 색상(tintColor) 변경
            button.tintColor = tintColor
            button.configuration = updatedConfig
        }
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }
    
    @objc private func handleTap() {
        isSelected.toggle()
        tapSubject.send(isSelected)
    }
}

