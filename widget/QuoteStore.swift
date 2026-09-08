//
//  QuoteStore.swift
//  widget
//

import Foundation

/// Ubicación compartida entre la app y el widget. Ambos targets corren sin sandbox,
/// así que resuelven la misma ruta en ~/Library/Application Support.
enum QuoteStore {
    static let directoryURL: URL = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("co.jgallo.rotatingquotes", isDirectory: true)

    static let fileURL: URL = directoryURL.appendingPathComponent("quotes.json")

    static func load() -> [Quote] {
        guard let data = try? Data(contentsOf: fileURL),
              let quotes = try? JSONDecoder().decode([Quote].self, from: data) else {
            return []
        }

        return quotes.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}
