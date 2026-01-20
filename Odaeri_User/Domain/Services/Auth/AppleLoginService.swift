//
//  AppleLoginService.swift
//  Odaeri_User
//
//  Created by 박성훈 on 1/19/26.
//

import Foundation
import AuthenticationServices
import Combine
import UIKit

protocol AppleLoginServiceProtocol {
    func login() -> AnyPublisher<String, Error>
}

final class DefaultAppleLoginService: NSObject, AppleLoginServiceProtocol {
    private var promise: ((Result<String, Error>) -> Void)?
    private var authorizationController: ASAuthorizationController?

    func login() -> AnyPublisher<String, Error> {
        Future<String, Error> { [weak self] promise in
            guard let self else { return }

            self.promise = promise

            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.email, .fullName]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            self.authorizationController = controller
            controller.performRequests()
        }
        .eraseToAnyPublisher()
    }
}

extension DefaultAppleLoginService: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            print("[AppleLoginService] Failed to extract identityToken.")
            promise?(.failure(NSError(domain: "AppleLoginService", code: -1)))
            clearAuthorization()
            return
        }

        if let email = credential.email {
            print("[AppleLoginService] Email received: \(email)")
        } else {
            print("[AppleLoginService] Email not provided by Apple (likely already authorized).")
        }
        print("[AppleLoginService] identityToken extracted. length=\(idToken.count)")
        promise?(.success(idToken))
        clearAuthorization()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("[AppleLoginService] Authorization error: \(error.localizedDescription)")
        promise?(.failure(error))
        clearAuthorization()
    }
}

extension DefaultAppleLoginService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let activeScene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        let window = activeScene?.windows.first { $0.isKeyWindow } ?? activeScene?.windows.first
        return window ?? UIWindow()
    }
}

private extension DefaultAppleLoginService {
    func clearAuthorization() {
        promise = nil
        authorizationController = nil
    }
}
