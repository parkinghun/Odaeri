//
//  ChatCollectionViewLayout.swift
//  Odaeri
//
//  Created by 박성훈 on 01/22/26.
//

import UIKit

final class ChatCollectionViewLayout: UICollectionViewLayout {
    override class var layoutAttributesClass: AnyClass {
        return ChatCollectionViewLayoutAttributes.self
    }

    private var cachedAttributes: [ChatCollectionViewLayoutAttributes] = []
    private var contentHeight: CGFloat = 0

    var layoutDataProvider: ((IndexPath) -> ChatCellLayoutData?)?

    override func prepare() {
        super.prepare()

        guard let collectionView = collectionView,
              let layoutDataProvider = layoutDataProvider else {
            return
        }

        cachedAttributes.removeAll()
        contentHeight = 0

        guard collectionView.numberOfSections > 0 else { return }

        let numberOfItems = collectionView.numberOfItems(inSection: 0)

        guard numberOfItems > 0 else { return }

        var currentY: CGFloat = 0

        for item in 0..<numberOfItems {
            let indexPath = IndexPath(item: item, section: 0)

            guard let layoutData = layoutDataProvider(indexPath) else {
                continue
            }

            let attributes = ChatCollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.cellLayoutData = layoutData

            let contentSize: CGSize
            switch layoutData {
            case .message(let messageLayoutData):
                contentSize = messageLayoutData.contentSize
            case .dateSeparator(let separatorLayoutData):
                contentSize = separatorLayoutData.contentSize
            case .default:
                contentSize = CGSize(width: collectionView.bounds.width, height: 75)
            }

            attributes.frame = CGRect(
                x: 0,
                y: currentY,
                width: contentSize.width,
                height: contentSize.height
            )

            cachedAttributes.append(attributes)
            currentY += contentSize.height
        }

        contentHeight = currentY
    }

    override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView else {
            return .zero
        }
        return CGSize(width: collectionView.bounds.width, height: contentHeight)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard !cachedAttributes.isEmpty else { return nil }

        var visibleAttributes: [UICollectionViewLayoutAttributes] = []

        for attributes in cachedAttributes {
            if attributes.frame.maxY < rect.minY {
                continue
            }

            if attributes.frame.minY > rect.maxY {
                break
            }

            if attributes.frame.intersects(rect) {
                visibleAttributes.append(attributes)
            }
        }

        return visibleAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.item >= 0, indexPath.item < cachedAttributes.count else {
            return nil
        }
        return cachedAttributes[indexPath.item]
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView = collectionView else { return false }
        return newBounds.width != collectionView.bounds.width
    }

    override func invalidateLayout() {
        super.invalidateLayout()
        cachedAttributes.removeAll()
        contentHeight = 0
    }
}
