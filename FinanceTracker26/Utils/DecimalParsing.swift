import Foundation

enum DecimalParsing {
    static func extractFirstDecimal(from text: String) -> Decimal? {
        let cleaned = text
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Find a number-like substring, allowing thousands separators and decimal separators.
        // Examples: 1,234.56  | 1.234,56 | 24,85
        let pattern = #"[-+]?\d{1,3}([\.,]\d{3})*([\.,]\d+)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let range = NSRange(cleaned.startIndex..<cleaned.endIndex, in: cleaned)
        guard let match = regex.firstMatch(in: cleaned, options: [], range: range) else { return nil }
        guard let matchRange = Range(match.range, in: cleaned) else { return nil }

        let token = String(cleaned[matchRange])
        return parseFlexible(token)
    }

    static func parseFlexible(_ token: String) -> Decimal? {
        var s = token.trimmingCharacters(in: .whitespacesAndNewlines)

        // Decide decimal separator by last occurrence.
        let lastDot = s.lastIndex(of: ".")
        let lastComma = s.lastIndex(of: ",")

        if let lastDot, let lastComma {
            // Both present: whichever comes later is the decimal separator.
            if lastDot > lastComma {
                // dot decimal, remove commas
                s = s.replacingOccurrences(of: ",", with: "")
            } else {
                // comma decimal, remove dots, replace comma with dot
                s = s.replacingOccurrences(of: ".", with: "")
                s = s.replacingOccurrences(of: ",", with: ".")
            }
        } else if lastComma != nil {
            // Only comma: treat as decimal separator
            s = s.replacingOccurrences(of: ".", with: "")
            s = s.replacingOccurrences(of: ",", with: ".")
        } else {
            // Only dot or none: remove commas as thousands
            s = s.replacingOccurrences(of: ",", with: "")
        }

        return Decimal(string: s, locale: Locale(identifier: "en_US_POSIX"))
    }
}
