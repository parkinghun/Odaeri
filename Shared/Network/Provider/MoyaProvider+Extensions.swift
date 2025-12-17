//
//  MoyaProvider+Extensions.swift
//  Odaeri
//
//  Created by 박성훈 on 12/17/25.
//

import Foundation
import Moya

extension MoyaProvider {
    func request<T: Decodable>(_ target: Target, timeout: TimeInterval = 10) async throws -> T {
        let provider = self.withTimeout(timeout)

        return try await withCheckedThrowingContinuation { continuation in
            provider.request(target) { result in
                switch result {
                case .success(let response):
                    do {
                        let decodedData = try response.map(T.self)
                        continuation.resume(returning: decodedData)
                    } catch {
                        if let networkError = self.parseError(from: response) {
                            continuation.resume(throwing: networkError)
                        } else {
                            continuation.resume(throwing: NetworkError.decodingFailed(error))
                        }
                    }
                case .failure(let moyaError):
                    continuation.resume(throwing: self.handleMoyaError(moyaError))
                }
            }
        }
    }

    func requestWithoutResponse(_ target: Target, timeout: TimeInterval = 10) async throws {
        let provider = self.withTimeout(timeout)

        return try await withCheckedThrowingContinuation { continuation in
            provider.request(target) { result in
                switch result {
                case .success(let response):
                    if let networkError = self.parseError(from: response) {
                        continuation.resume(throwing: networkError)
                    } else {
                        continuation.resume()
                    }
                case .failure(let moyaError):
                    continuation.resume(throwing: self.handleMoyaError(moyaError))
                }
            }
        }
    }

    private func withTimeout(_ timeout: TimeInterval) -> MoyaProvider<Target> {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout * 2

        let session = Session(configuration: configuration)

        return MoyaProvider<Target>(session: session, plugins: self.plugins)
    }

    private func parseError(from response: Response) -> NetworkError? {
        let statusCode = response.statusCode

        guard !(200...299).contains(statusCode) else {
            return nil
        }

        if statusCode == 419 {
            return .accessTokenExpired
        }

        if let errorResponse = try? response.map(ErrorResponse.self) {
            return .serverError(statusCode: statusCode, message: errorResponse.message)
        }

        return .serverError(statusCode: statusCode, message: "알 수 없는 서버 오류")
    }

    private func handleMoyaError(_ moyaError: MoyaError) -> NetworkError {
        switch moyaError {
        case .underlying(let error, _):
            let nsError = error as NSError

            if nsError.domain == NSURLErrorDomain {
                switch nsError.code {
                case NSURLErrorNotConnectedToInternet,
                     NSURLErrorNetworkConnectionLost:
                    return .noInternetConnection
                case NSURLErrorTimedOut:
                    return .timeout
                default:
                    break
                }
            }

            return .unknown(error)

        case .statusCode(let response):
            if let networkError = parseError(from: response) {
                return networkError
            }
            return .unknown(moyaError)

        default:
            return .unknown(moyaError)
        }
    }
}
