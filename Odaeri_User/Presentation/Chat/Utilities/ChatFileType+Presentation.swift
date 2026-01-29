//
//  ChatFileType+Presentation.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/28/26.
//

import UIKit

extension ChatFileType {
    var icon: UIImage {
        switch self {
        case .pdf:
            return AppImage.pdf
                .withRenderingMode(.alwaysOriginal)
        case .zip:
            return AppImage.zip
                .withRenderingMode(.alwaysOriginal)
        case .other:
            return AppImage.document
                .withRenderingMode(.alwaysOriginal)
        }
    }
}
