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

    func resizeToMaxDimension(_ maxDimension: CGFloat) -> UIImage {
        let currentSize = self.size
        let longerSide = max(currentSize.width, currentSize.height)

        if longerSide <= maxDimension {
            return self
        }

        let scale = maxDimension / longerSide
        let newSize = CGSize(
            width: currentSize.width * scale,
            height: currentSize.height * scale
        )

        return resize(to: newSize)
    }

    func compressToJPEG(quality: CGFloat = 0.8) -> Data? {
        return jpegData(compressionQuality: quality)
    }

    func processForUpload(maxDimension: CGFloat, compressionQuality: CGFloat = 0.8) -> Data? {
        let resized = resizeToMaxDimension(maxDimension)
        return resized.compressToJPEG(quality: compressionQuality)
    }
}
