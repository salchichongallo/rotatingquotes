//
//  QuoteStore.swift
//  rotatingquotes
//

import Foundation
import Observation
import SwiftUI
import WidgetKit

struct Quote: Identifiable, Hashable, Codable {
    var id = UUID()
    var text: String
    var author: String = ""

    private enum CodingKeys: String, CodingKey {
        case text, author
    }

    init(text: String, author: String = "") {
        self.text = text
        self.author = author
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        author = try container.decodeIfPresent(String.self, forKey: .author) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        if !author.isEmpty {
            try container.encode(author, forKey: .author)
        }
    }
}

/// El widget corre en sandbox (macOS lo exige en extensiones de widget) y esta app no,
/// así que la app escribe directamente en el contenedor del widget, que es donde la
/// extensión resuelve su propio directorio de Application Support.
enum QuoteStore {
    static let directoryURL: URL = URL(fileURLWithPath: NSHomeDirectory())
        .appendingPathComponent("Library/Containers/co.jgallo.rotatingquotes.widget/Data/Library/Application Support", isDirectory: true)
        .appendingPathComponent("co.jgallo.rotatingquotes", isDirectory: true)

    static let fileURL: URL = directoryURL.appendingPathComponent("quotes.json")

    static let defaults: [Quote] = [
        Quote(text: "I leave you the best of myself"),
        Quote(text: "The future belongs to those who learn more skills and combine them in creative ways"),
        Quote(text: "Is there a way that I can win doing this even if I fail?"),
        Quote(text: "You do not rise to the level of your goals, you fall to the level of your systems", author: "James Clear"),
        Quote(text: "The obstacle is the way", author: "Marcus Aurelius"),
        Quote(text: "Simplicity is the ultimate sophistication", author: "Leonardo da Vinci"),
        Quote(text: "What you do every day matters more than what you do once in a while"),
        Quote(text: "Compare yourself to who you were yesterday, not to who someone else is today"),
        Quote(text: "The best time to plant a tree was twenty years ago. The second best time is now"),
        Quote(text: "Amateurs wait for inspiration. Professionals get to work"),
        Quote(text: "Make it work, make it right, make it fast", author: "Kent Beck"),
        Quote(text: "Slow is smooth, and smooth is fast"),
    ]

    static func load() -> [Quote] {
        guard let data = try? Data(contentsOf: fileURL),
              let quotes = try? JSONDecoder().decode([Quote].self, from: data) else {
            return []
        }

        return quotes
    }

    static func save(_ quotes: [Quote]) throws {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]

        let usable = quotes.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        try encoder.encode(usable).write(to: fileURL, options: .atomic)
    }
}

@Observable
final class QuotesModel {
    var quotes: [Quote]
    private(set) var status = ""

    private var saveTask: Task<Void, Never>?

    init() {
        let loaded = QuoteStore.load()
        quotes = loaded.isEmpty ? QuoteStore.defaults : loaded

        if loaded.isEmpty {
            persist()
        }
    }

    func add() {
        quotes.append(Quote(text: ""))
    }

    func remove(atOffsets offsets: IndexSet) {
        quotes.remove(atOffsets: offsets)
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        quotes.move(fromOffsets: source, toOffset: destination)
    }

    func restoreDefaults() {
        quotes = QuoteStore.defaults
    }

    /// Se guarda tras una pausa para no escribir en cada pulsación de tecla.
    func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            self?.persist()
        }
    }

    private func persist() {
        do {
            try QuoteStore.save(quotes)
            WidgetCenter.shared.reloadAllTimelines()
            status = "Guardado"
        } catch {
            status = "No se pudo guardar: \(error.localizedDescription)"
        }
    }
}
