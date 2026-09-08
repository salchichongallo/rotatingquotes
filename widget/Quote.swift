//
//  Quote.swift
//  widget
//

import Foundation

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

/// Deterministic PRNG (SplitMix64) so a given seed always yields the same shuffle.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed &+ 0x9E37_79B9_7F4A_7C15
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

enum QuoteLibrary {
    static let rotationInterval: TimeInterval = 5 * 60

    static let placeholder = Quote(text: "Abre rotatingquotes para añadir tus frases")

    /// Start of the 5-minute slot that contains `date`.
    static func slotStart(for date: Date) -> Date {
        let slot = floor(date.timeIntervalSince1970 / rotationInterval)
        return Date(timeIntervalSince1970: slot * rotationInterval)
    }

    static func nextSlot(after date: Date) -> Date {
        slotStart(for: date).addingTimeInterval(rotationInterval)
    }

    /// Picks the quote for `date`. Each cycle of `quotes.count` slots shows every quote
    /// exactly once, in an order that is random per cycle but reproducible.
    /// `offset` shifts the sequence by whole slots without breaking that guarantee.
    static func quote(at date: Date, offset: Int = 0, from quotes: [Quote]) -> Quote {
        guard !quotes.isEmpty else { return placeholder }

        let count = quotes.count
        let slot = Int(floor(date.timeIntervalSince1970 / rotationInterval)) + offset
        let cycleIndex = Int(floor(Double(slot) / Double(count)))
        let position = ((slot % count) + count) % count

        return quotes[order(forCycle: cycleIndex, count: count)[position]]
    }

    private static func shuffledIndices(forCycle cycle: Int, count: Int) -> [Int] {
        var generator = SeededGenerator(seed: UInt64(bitPattern: Int64(cycle)))
        return Array(0 ..< count).shuffled(using: &generator)
    }

    private static func order(forCycle cycle: Int, count: Int) -> [Int] {
        var order = shuffledIndices(forCycle: cycle, count: count)

        // Keep the same quote from spanning a cycle boundary. The adjustment only touches
        // the first two slots, so the previous cycle's last index is its unadjusted one.
        if count > 2,
           let previousLast = shuffledIndices(forCycle: cycle - 1, count: count).last,
           order[0] == previousLast {
            order.swapAt(0, 1)
        }

        return order
    }
}
