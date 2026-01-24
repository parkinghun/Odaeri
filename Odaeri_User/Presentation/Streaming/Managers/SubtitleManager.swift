//
//  SubtitleManager.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/22/26.
//

import AVFoundation
import Combine

final class SubtitleManager {
    private weak var player: AVPlayer?
    private var cancellables = Set<AnyCancellable>()

    private static let languageMap: [String: String] = [
        "ko": "한국어",
        "en": "English",
        "ja": "日本語",
        "zh": "中文",
        "fr": "Français",
        "es": "Español",
        "de": "Deutsch"
    ]

    private let availableSubtitlesSubject = CurrentValueSubject<[SubtitleTrack], Never>([])
    private let currentSubtitleSubject = CurrentValueSubject<SubtitleTrack?, Never>(nil)

    var availableSubtitlesPublisher: AnyPublisher<[SubtitleTrack], Never> {
        availableSubtitlesSubject.eraseToAnyPublisher()
    }

    var currentSubtitlePublisher: AnyPublisher<SubtitleTrack?, Never> {
        currentSubtitleSubject.eraseToAnyPublisher()
    }

    init(player: AVPlayer) {
        self.player = player
        observePlayerItem()
    }

    private func observePlayerItem() {
        guard let player = player else { return }

        player.publisher(for: \.currentItem, options: [.new])
            .sink { [weak self] item in
                self?.handlePlayerItemChange(item)
            }
            .store(in: &cancellables)
    }

    private func handlePlayerItemChange(_ item: AVPlayerItem?) {
        guard let item = item else {
            availableSubtitlesSubject.send([])
            return
        }

        let subtitles = extractSubtitles(from: item)
        availableSubtitlesSubject.send(subtitles)

        print("[SubtitleManager] Found \(subtitles.count) subtitle tracks:")
        for subtitle in subtitles {
            print("  - \(subtitle.name) (\(subtitle.language))")
        }

        if let defaultSubtitle = subtitles.first(where: { $0.isDefault }) {
            selectSubtitle(defaultSubtitle)
        }
    }

    private func extractSubtitles(from item: AVPlayerItem) -> [SubtitleTrack] {
        var tracks: [SubtitleTrack] = []

        let legibleGroup = item.asset.mediaSelectionGroup(forMediaCharacteristic: .legible)

        if let group = legibleGroup {
            for option in group.options {
                let languageCode = extractLanguageCode(from: option)
                let displayName = createDisplayName(for: option, languageCode: languageCode)

                let track = SubtitleTrack(
                    id: option.displayName,
                    language: languageCode,
                    name: displayName,
                    isDefault: false,
                    source: .embedded(option)
                )
                tracks.append(track)
            }
        }

        let offTrack = SubtitleTrack(
            id: "off",
            language: "off",
            name: "자막 끄기",
            isDefault: true,
            source: .none
        )
        tracks.insert(offTrack, at: 0)

        return tracks
    }

    private func extractLanguageCode(from option: AVMediaSelectionOption) -> String {
        if let extendedTag = option.extendedLanguageTag {
            let components = extendedTag.split(separator: "-")
            return String(components.first ?? "unknown").lowercased()
        }
        return "unknown"
    }

    private func createDisplayName(for option: AVMediaSelectionOption, languageCode: String) -> String {
        if let languageName = Self.languageMap[languageCode] {
            return languageName
        }

        if let displayName = option.displayName as String?, !displayName.isEmpty {
            return displayName
        }

        return languageCode.uppercased()
    }

    func selectSubtitle(_ track: SubtitleTrack) {
        guard let player = player,
              let item = player.currentItem else { return }

        guard let group = item.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) else {
            print("[SubtitleManager] No legible media selection group available")
            return
        }

        switch track.source {
        case .embedded(let option):
            item.select(option, in: group)
            currentSubtitleSubject.send(track)
            print("[SubtitleManager] Selected subtitle: \(track.name)")

            if let currentSelection = item.currentMediaSelection.selectedMediaOption(in: group) {
                print("[SubtitleManager] Current selection confirmed: \(currentSelection.displayName)")
            }

        case .external:
            break

        case .none:
            item.select(nil, in: group)
            currentSubtitleSubject.send(track)
            print("[SubtitleManager] Subtitles turned off")
        }
    }

    func addExternalSubtitle(url: URL, language: String, name: String) {
    }
}

struct SubtitleTrack: Hashable, Equatable {
    let id: String
    let language: String
    let name: String
    let isDefault: Bool
    let source: SubtitleSource

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SubtitleTrack, rhs: SubtitleTrack) -> Bool {
        return lhs.id == rhs.id
    }
}

enum SubtitleSource: Hashable {
    case embedded(AVMediaSelectionOption)
    case external(URL)
    case none

    func hash(into hasher: inout Hasher) {
        switch self {
        case .embedded(let option):
            hasher.combine("embedded")
            hasher.combine(option.displayName)
        case .external(let url):
            hasher.combine("external")
            hasher.combine(url)
        case .none:
            hasher.combine("none")
        }
    }

    static func == (lhs: SubtitleSource, rhs: SubtitleSource) -> Bool {
        switch (lhs, rhs) {
        case (.embedded(let lOption), .embedded(let rOption)):
            return lOption.displayName == rOption.displayName
        case (.external(let lURL), .external(let rURL)):
            return lURL == rURL
        case (.none, .none):
            return true
        default:
            return false
        }
    }
}
