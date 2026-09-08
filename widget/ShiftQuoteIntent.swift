//
//  ShiftQuoteIntent.swift
//  widget
//

import AppIntents
import Foundation

/// El intent y el timeline provider corren en el mismo proceso de la extensión,
/// así que no hace falta un App Group para compartir este valor.
enum QuoteOffsetStore {
    private static let key = "quoteSlotOffset"

    static var offset: Int {
        UserDefaults.standard.integer(forKey: key)
    }

    static func shift(by delta: Int) {
        UserDefaults.standard.set(offset + delta, forKey: key)
    }
}

struct ShiftQuoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Adjacent Quote"

    @Parameter(title: "Offset")
    var offset: Int

    init() {}

    init(offset: Int) {
        self.offset = offset
    }

    func perform() async throws -> some IntentResult {
        QuoteOffsetStore.shift(by: offset)
        return .result()
    }
}
