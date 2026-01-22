//
//  SceneDelegate.swift
//  Odaeri
//
//  Created by 박성훈 on 12/10/25.
//

import UIKit
import KakaoSDKAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var appCoordinator: AppCoordinator?
    private var pendingRoomId: String?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window

        appCoordinator = AppCoordinator(window: window)
        appCoordinator?.start()

        if let response = connectionOptions.notificationResponse {
            let userInfo = response.notification.request.content.userInfo
            pendingRoomId = NotificationPayload.roomId(from: userInfo)
        }

        if let roomId = pendingRoomId {
            pendingRoomId = nil
            appCoordinator?.handleChatDeepLink(roomId: roomId)
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            if (AuthApi.isKakaoTalkLoginUrl(url)) {
                _ = AuthController.handleOpenUrl(url: url)
            }
        }
    }

  func sceneDidDisconnect(_ scene: UIScene) {
    // Called as the scene is being released by the system.
    // This occurs shortly after the scene enters the background, or when its session is discarded.
    // Release any resources associated with this scene that can be re-created the next time the scene connects.
    // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
  }

  func sceneDidBecomeActive(_ scene: UIScene) {
    // Called when the scene has moved from an inactive state to an active state.
    // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
      UIApplication.shared.applicationIconBadgeNumber = 0
  }

  func sceneWillResignActive(_ scene: UIScene) {
    // Called when the scene will move from an active state to an inactive state.
    // This may occur due to temporary interruptions (ex. an incoming phone call).
  }

  func sceneWillEnterForeground(_ scene: UIScene) {
    // Called as the scene transitions from the background to the foreground.
    // Use this method to undo the changes made on entering the background.
      checkSessionInvalidation()
  }

    private func checkSessionInvalidation() {
        guard TokenManager.shared.isSessionInvalidated else { return }

        TokenManager.shared.clearSessionInvalidationFlag()

        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let windowScene = self.window?.windowScene,
                  windowScene.activationState == .foregroundActive else { return }

            let alert = UIAlertController(
                title: "세션 종료",
                message: "다른 기기에서 로그인되어 세션이 종료되었습니다.\n다시 로그인해주세요.",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
                self?.appCoordinator?.showAuthFlow()
            })

            self.window?.rootViewController?.present(alert, animated: true)
        }
    }

  func sceneDidEnterBackground(_ scene: UIScene) {
    // Called as the scene transitions from the foreground to the background.
    // Use this method to save data, release shared resources, and store enough scene-specific state information
    // to restore the scene back to its current state.
  }

    func handlePushDeepLink(roomId: String) {
        if let appCoordinator = appCoordinator {
            appCoordinator.handleChatDeepLink(roomId: roomId)
        } else {
            pendingRoomId = roomId
        }
    }

}
