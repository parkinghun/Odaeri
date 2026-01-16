//
//  FilePathManager.swift
//  Odaeri
//
//  Created by 박성훈 on 1/13/26.
//

import Foundation

final class FilePathManager {
    private static let chatUploadsDirectory = "ChatUploads"

    static func createChatUploadsDirectory() -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(chatUploadsDirectory, isDirectory: true)

        if !FileManager.default.fileExists(atPath: tempDirectory.path) {
            do {
                try FileManager.default.createDirectory(
                    at: tempDirectory,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                return tempDirectory
            } catch {
                print("ChatUploads 폴더 생성 실패: \(error)")
                return nil
            }
        }

        return tempDirectory
    }

    static func getChatUploadsDirectory() -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(chatUploadsDirectory, isDirectory: true)

        guard FileManager.default.fileExists(atPath: tempDirectory.path) else {
            return createChatUploadsDirectory()
        }

        return tempDirectory
    }

    static func getFileURL(from fileString: String) -> URL? {
        guard !fileString.isEmpty else {
            print("[FilePathManager] 빈 문자열 입력")
            return nil
        }

        let normalizedFileName = normalizeToFileName(fileString)

        guard let directory = getChatUploadsDirectory() else {
            print("[FilePathManager] ChatUploads 디렉토리 생성 실패")
            return nil
        }

        let fileURL = directory.appendingPathComponent(normalizedFileName)
        let fileExists = FileManager.default.fileExists(atPath: fileURL.path)

        print("[FilePathManager] 파일 조회")
        print("  - 입력: \(fileString)")
        print("  - 정규화된 파일명: \(normalizedFileName)")
        print("  - 최종 경로: \(fileURL.path)")
        print("  - 파일 존재: \(fileExists)")

        guard fileExists else {
            print("[FilePathManager] ⚠️ 파일이 존재하지 않음")

            if fileString.hasPrefix("file://"), let fallbackURL = URL(string: fileString) {
                let fallbackExists = FileManager.default.fileExists(atPath: fallbackURL.path)
                print("[FilePathManager] 백업: 절대 경로로 재시도 - 존재: \(fallbackExists)")
                if fallbackExists {
                    return fallbackURL
                }
            }

            return nil
        }

        return fileURL
    }

    private static func normalizeToFileName(_ input: String) -> String {
        if input.hasPrefix("file://") {
            if let url = URL(string: input) {
                return url.lastPathComponent
            }
        }

        if input.contains("/") {
            return input.lastPathComponent
        }

        return input
    }

    static func saveFile(at sourceURL: URL, fileName: String? = nil) -> String? {
        guard let directory = createChatUploadsDirectory() else {
            return nil
        }

        let originalFileName = fileName ?? sourceURL.lastPathComponent
        let safeFileName = originalFileName.isEmpty ? "\(UUID().uuidString)" : originalFileName
        var destinationURL = directory.appendingPathComponent(safeFileName)

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            let uniqueFileName = "\(UUID().uuidString)_\(safeFileName)"
            destinationURL = directory.appendingPathComponent(uniqueFileName)
        }

        do {
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            return destinationURL.lastPathComponent
        } catch {
            print("파일 복사 실패: \(error)")
            return nil
        }
    }

    static func saveImageData(_ data: Data, fileName: String? = nil) -> String? {
        guard let directory = createChatUploadsDirectory() else {
            return nil
        }

        let safeFileName = fileName ?? "image_\(UUID().uuidString).jpg"
        let destinationURL = directory.appendingPathComponent(safeFileName)

        do {
            try data.write(to: destinationURL)
            return destinationURL.lastPathComponent
        } catch {
            print("이미지 저장 실패: \(error)")
            return nil
        }
    }

    static func cleanupChatUploads() {
        guard let directory = getChatUploadsDirectory() else {
            return
        }

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil
            )

            for fileURL in fileURLs {
                try? FileManager.default.removeItem(at: fileURL)
            }

            print("ChatUploads 폴더 정리 완료: \(fileURLs.count)개 파일 삭제")
        } catch {
            print("ChatUploads 폴더 정리 실패: \(error)")
        }
    }

    static func removeFile(fileName: String) {
        let normalizedFileName = normalizeToFileName(fileName)

        guard let fileURL = getFileURL(from: normalizedFileName) else {
            print("[FilePathManager] 삭제 실패: 파일을 찾을 수 없음")
            print("  - 입력: \(fileName)")
            print("  - 정규화: \(normalizedFileName)")
            return
        }

        do {
            try FileManager.default.removeItem(at: fileURL)
            print("[FilePathManager] 파일 삭제 완료: \(normalizedFileName)")
        } catch {
            print("[FilePathManager] 파일 삭제 실패: \(error)")
        }
    }
}
