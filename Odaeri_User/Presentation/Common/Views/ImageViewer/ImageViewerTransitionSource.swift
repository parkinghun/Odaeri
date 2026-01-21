//
//  ImageViewerTransitionSource.swift
//  Odaeri
//
//  Created by 박성훈 on 01/21/26.
//

import UIKit

protocol ImageViewerTransitionSource: AnyObject {
    func frameForImage(at index: Int) -> CGRect?
    func imageView(at index: Int) -> UIImageView?
}
