//
//  ChatCollectionViewLayoutAttributes.swift
//  Odaeri
//
//  Created by 박성훈 on 01/22/26.
//

import UIKit

final class ChatCollectionViewLayoutAttributes: UICollectionViewLayoutAttributes {
    var cellLayoutData: ChatCellLayoutData = .default

    override func copy(with zone: NSZone? = nil) -> Any {
        guard let copy = super.copy(with: zone) as? ChatCollectionViewLayoutAttributes else {
            return super.copy(with: zone) as Any
        }
        copy.cellLayoutData = cellLayoutData
        return copy
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? ChatCollectionViewLayoutAttributes else {
            return false
        }

        if cellLayoutData != rhs.cellLayoutData {
            return false
        }

        return super.isEqual(object)
    }
}
