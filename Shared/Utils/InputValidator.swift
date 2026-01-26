//
//  InputValidator.swift
//  Odaeri
//
//  Created by 박성훈 on 01/24/26.
//

import Foundation

enum InputValidator {
    private static let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
    private static let nicknameForbiddenRegex = "[-\\.,\\?\\*\\@\\+\\^\\$\\{\\}\\(\\)\\|\\[\\]\\\\]"

    static func validateEmail(_ email: String) -> Bool {
        guard !email.isEmpty else { return false }
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }

    static func validatePassword(_ password: String) -> Bool {
        guard password.count >= 8 else { return false }
        let hasLetter = password.range(of: "[A-Za-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecial = password.range(of: "[@$!%*#?&]", options: .regularExpression) != nil
        return hasLetter && hasNumber && hasSpecial
    }

    static func validateNickname(_ nick: String) -> Bool {
        guard !nick.isEmpty else { return false }
        let hasForbidden = nick.range(of: nicknameForbiddenRegex, options: .regularExpression) != nil
        return !hasForbidden
    }

    static func emailValidationMessage(for email: String) -> String? {
        guard !email.isEmpty else { return nil }
        return validateEmail(email) ? nil : "유효한 이메일 형식이 아닙니다 (예: user@example.com)"
    }

    static func passwordValidationMessage(for password: String) -> String? {
        guard !password.isEmpty else { return nil }

        if password.count < 8 {
            return "비밀번호는 최소 8자 이상이어야 합니다"
        }

        let hasLetter = password.range(of: "[A-Za-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecial = password.range(of: "[@$!%*#?&]", options: .regularExpression) != nil

        if !hasLetter {
            return "영문자를 1개 이상 포함해야 합니다"
        }

        if !hasNumber {
            return "숫자를 1개 이상 포함해야 합니다"
        }

        if !hasSpecial {
            return "특수문자(@$!%*#?&)를 1개 이상 포함해야 합니다"
        }

        return nil
    }

    static func nicknameValidationMessage(for nick: String) -> String? {
        guard !nick.isEmpty else { return nil }
        return validateNickname(nick) ? nil : "닉네임에 사용할 수 없는 문자가 포함되어 있습니다"
    }
}
