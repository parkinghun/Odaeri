//
//  SceneDelegate.swift
//  Odaeri_Admin
//
//  Created by 박성훈 on 12/16/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        let rootViewController = makeRootViewController(window: window)
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
        self.window = window
    }

    private func makeRootViewController(window: UIWindow) -> UIViewController {
        if TokenManager.shared.isLoggedIn {
            return AdminSideTabBarController()
        } else {
            let loginViewModel = AdminLoginViewModel()
            let loginViewController = AdminLoginViewController(viewModel: loginViewModel)
            let navigationController = UINavigationController(rootViewController: loginViewController)
            navigationController.navigationBar.isHidden = true
            loginViewController.onLoginSuccess = { [weak window] in
                window?.rootViewController = AdminSideTabBarController()
                window?.makeKeyAndVisible()
            }
            return navigationController
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
                self?.showLoginScreen()
            })

            self.window?.rootViewController?.present(alert, animated: true)
        }
    }

    private func showLoginScreen() {
        TokenManager.shared.clearTokens()

        let loginViewModel = AdminLoginViewModel()
        let loginViewController = AdminLoginViewController(viewModel: loginViewModel)
        let navigationController = UINavigationController(rootViewController: loginViewController)
        navigationController.navigationBar.isHidden = true

        loginViewController.onLoginSuccess = { [weak self] in
            self?.window?.rootViewController = AdminSideTabBarController()
            self?.window?.makeKeyAndVisible()
        }

        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}
