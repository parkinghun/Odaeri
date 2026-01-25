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
    private let videoRepository: VideoRepository
    private var cancellables = Set<AnyCancellable>()

    private let availableSubtitlesSubject = CurrentValueSubject<[SubtitleTrack], Never>([])
    private let currentSubtitleSubject = CurrentValueSubject<SubtitleTrack?, Never>(nil)

    private var externalSubtitles: [String: [SubtitleItem]] = [:]
    private var currentExternalSubtitles: [SubtitleItem]?
    private var currentSubtitleIndex: Int = -1
    private var timeOffset: TimeInterval = 0

    private var externalSubtitleMetadata: [VideoSubtitleEntity] = []

    private let subtitleErrorSubject = PassthroughSubject<String, Never>()
    private let isLoadingSubtitleSubject = CurrentValueSubject<Bool, Never>(false)
    private let externalSubtitleDataSubject = CurrentValueSubject<[SubtitleItem]?, Never>(nil)
    private let currentSubtitleIndexSubject = CurrentValueSubject<Int?, Never>(nil)

    var availableSubtitlesPublisher: AnyPublisher<[SubtitleTrack], Never> {
        availableSubtitlesSubject.eraseToAnyPublisher()
    }

    var currentSubtitlePublisher: AnyPublisher<SubtitleTrack?, Never> {
        currentSubtitleSubject.eraseToAnyPublisher()
    }

    var subtitleErrorPublisher: AnyPublisher<String, Never> {
        subtitleErrorSubject.eraseToAnyPublisher()
    }

    var isLoadingSubtitlePublisher: AnyPublisher<Bool, Never> {
        isLoadingSubtitleSubject.eraseToAnyPublisher()
    }

    var externalSubtitleDataPublisher: AnyPublisher<[SubtitleItem]?, Never> {
        externalSubtitleDataSubject.eraseToAnyPublisher()
    }

    var currentSubtitleIndexPublisher: AnyPublisher<Int?, Never> {
        currentSubtitleIndexSubject.eraseToAnyPublisher()
    }

    init(player: AVPlayer, videoRepository: VideoRepository) {
        self.player = player
        self.videoRepository = videoRepository
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

        if let defaultSubtitle = subtitles.first(where: { $0.isDefault }) {
            selectSubtitle(defaultSubtitle)
        }
    }

    func setExternalSubtitleInfo(subtitles: [VideoSubtitleEntity]) {
        self.externalSubtitleMetadata = subtitles

        if let item = player?.currentItem {
            let tracks = extractSubtitles(from: item)
            availableSubtitlesSubject.send(tracks)
        }
    }

    private func extractSubtitles(from item: AVPlayerItem) -> [SubtitleTrack] {
        var tracks: [SubtitleTrack] = []

        for subtitleEntity in externalSubtitleMetadata {
            let track = SubtitleTrack(
                id: "external_\(subtitleEntity.language)",
                language: subtitleEntity.language,
                name: subtitleEntity.name,
                isDefault: subtitleEntity.isDefault,
                source: .external(URL(string: subtitleEntity.url)!)
            )
            tracks.append(track)
        }

        let offTrack = SubtitleTrack(
            id: "off",
            language: "off",
            name: "스크립트 끄기",
            isDefault: externalSubtitleMetadata.isEmpty,
            source: .none
        )
        tracks.insert(offTrack, at: 0)

        return tracks
    }

    func selectSubtitle(_ track: SubtitleTrack) {
        guard let player = player,
              let item = player.currentItem else { return }

        if let group = item.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
            item.select(nil, in: group)
        }

        switch track.source {
        case .external(let url):
            currentSubtitleSubject.send(track)

            if externalSubtitles[track.language] != nil {
                currentExternalSubtitles = externalSubtitles[track.language]
                externalSubtitleDataSubject.send(currentExternalSubtitles)
            } else {
                let subtitleMetadata = externalSubtitleMetadata.first(where: { $0.language == track.language })
                if let path = subtitleMetadata?.url {
                    addExternalSubtitle(path: path, language: track.language, name: track.name)
                } else {
                }
            }

        case .none:
            currentSubtitleSubject.send(track)
            currentExternalSubtitles = nil
            externalSubtitleDataSubject.send(nil)

        case .embedded:
            break
        }
    }

    func updateCurrentSubtitleIndex(time: TimeInterval) {
        guard let subtitles = currentExternalSubtitles else {
            currentSubtitleIndexSubject.send(nil)
            return
        }

        let adjustedTime = time + timeOffset
        let newIndex = findSubtitleIndex(at: adjustedTime, in: subtitles)

        if newIndex != currentSubtitleIndex {
            currentSubtitleIndex = newIndex
            currentSubtitleIndexSubject.send(newIndex >= 0 ? newIndex : nil)
        }
    }

    private func findSubtitleIndex(at time: TimeInterval, in subtitles: [SubtitleItem]) -> Int {
        guard !subtitles.isEmpty else { return -1 }

        var left = 0
        var right = subtitles.count - 1

        while left <= right {
            let mid = (left + right) / 2
            let subtitle = subtitles[mid]

            if time < subtitle.startTime {
                right = mid - 1
            } else if time > subtitle.endTime {
                left = mid + 1
            } else {
                return mid
            }
        }

        return -1
    }

    func adjustTimeOffset(_ offset: TimeInterval) {
        timeOffset = offset
    }

    func addExternalSubtitle(path: String, language: String, name: String) {
        isLoadingSubtitleSubject.send(true)

        videoRepository.getSubtitleFile(path: path)
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .map { vttString in
                SubtitleParser.parse(vttString)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoadingSubtitleSubject.send(false)

                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    let message: String
                    switch error {
                    case .unauthorized:
                        message = "자막 접근 권한이 없습니다"
                    case .serverError(let statusCode, _):
                        if statusCode == 403 {
                            message = "자막 접근 권한이 없습니다"
                        } else if statusCode == 404 {
                            message = "자막 파일을 찾을 수 없습니다"
                        } else {
                            message = "자막 다운로드 실패 (상태 코드: \(statusCode))"
                        }
                    default:
                        message = "자막 다운로드 실패: \(error.errorDescription)"
                    }
                    self.subtitleErrorSubject.send(message)
                }
            } receiveValue: { [weak self] subtitles in
                guard let self = self else { return }

                if subtitles.isEmpty {
                    self.subtitleErrorSubject.send("자막 파싱에 실패했습니다")
                } else {
                    self.externalSubtitles[language] = subtitles
                    self.currentExternalSubtitles = subtitles
                    self.externalSubtitleDataSubject.send(subtitles)
                }
            }
            .store(in: &cancellables)
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
