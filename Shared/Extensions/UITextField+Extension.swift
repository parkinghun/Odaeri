//
//  UITextField+Extension.swift
//  Odaeri
//
//  Created by 박성훈 on 12/19/25.
//

import UIKit
import Combine

extension UITextField {
    var textPublisher: AnyPublisher<String, Never> {
        NotificationCenter.default.publisher(
            for: UITextField.textDidChangeNotification,
            object: self
        )
        .compactMap { ($0.object as? UITextField)?.text }
        .prepend(text ?? "")
        .eraseToAnyPublisher()
    }
}
