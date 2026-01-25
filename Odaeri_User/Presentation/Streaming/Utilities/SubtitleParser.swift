//
//  SubtitleParser.swift
//  Odaeri_User
//
//  Created by 박성훈 on 01/23/26.
//

import Foundation

enum SubtitleParser {
    static func parse(_ vttString: String) -> [SubtitleItem] {
        guard vttString.hasPrefix("WEBVTT") else {
            return []
        }

        let blocks = vttString.components(separatedBy: "\n\n")
        var subtitles: [SubtitleItem] = []

        for block in blocks {
            if let subtitle = parseBlock(block) {
                subtitles.append(subtitle)
            }
        }

        return subtitles
    }

    private static func parseBlock(_ block: String) -> SubtitleItem? {
        let lines = block.components(separatedBy: "\n").filter { !$0.isEmpty }

        guard !lines.isEmpty else { return nil }

        let timecodePattern = "([0-9:.]+)\\s*-->\\s*([0-9:.]+)"
        let regex = try? NSRegularExpression(pattern: timecodePattern)

        var timecodeLineIndex: Int?
        var startTime: TimeInterval?
        var endTime: TimeInterval?

        for (index, line) in lines.enumerated() {
            if let match = regex?.firstMatch(
                in: line,
                range: NSRange(line.startIndex..., in: line)
            ) {
                timecodeLineIndex = index

                if let startRange = Range(match.range(at: 1), in: line) {
                    let startString = String(line[startRange])
                    startTime = parseTimecode(startString)
                }

                if let endRange = Range(match.range(at: 2), in: line) {
                    let endString = String(line[endRange])
                    endTime = parseTimecode(endString)
                }

                break
            }
        }

        guard let timecodeIndex = timecodeLineIndex,
              let start = startTime,
              let end = endTime else {
            return nil
        }

        let textLines = lines[(timecodeIndex + 1)...]
        let text = textLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else { return nil }

        return SubtitleItem(startTime: start, endTime: end, text: text)
    }

    private static func parseTimecode(_ timecode: String) -> TimeInterval? {
        let components = timecode.components(separatedBy: ":")

        guard components.count >= 2 else { return nil }

        var hours: Double = 0
        var minutes: Double = 0
        var seconds: Double = 0

        if components.count == 3 {
            hours = Double(components[0]) ?? 0
            minutes = Double(components[1]) ?? 0
            seconds = Double(components[2]) ?? 0
        } else if components.count == 2 {
            minutes = Double(components[0]) ?? 0
            seconds = Double(components[1]) ?? 0
        }

        return hours * 3600 + minutes * 60 + seconds
    }
}
