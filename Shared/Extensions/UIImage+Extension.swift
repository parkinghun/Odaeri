//
//  UIImage+Extension.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/2/26.
//

import UIKit

extension UIImage {
    func resize(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
