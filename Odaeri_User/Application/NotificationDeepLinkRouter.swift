//
//  NotificationDeepLinkRouter.swift
//  Odaeri
//
//  Created by 박성훈 on 1/13/26.
//

import UIKit

enum NotificationDeepLinkRouter {
    static func routeToChatRoom(roomId: String) {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else {
            return
        }

        guard let sceneDelegate = scene.delegate as? SceneDelegate else {
            return
        }

        sceneDelegate.handlePushDeepLink(roomId: roomId)
    }
}
