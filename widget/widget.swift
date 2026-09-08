//
//  widget.swift
//  widget
//
//  Created by Jaime Gallo on 8/09/26.
//

import AppIntents
import WidgetKit
import SwiftUI

struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: Quote
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(date: Date(), quote: QuoteStore.load().first ?? QuoteLibrary.placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> ()) {
        let now = Date()
        let quotes = QuoteStore.load()
        completion(QuoteEntry(date: now, quote: QuoteLibrary.quote(at: now, offset: QuoteOffsetStore.offset, from: quotes)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> ()) {
        // One entry per 5-minute slot, aligned to slot boundaries, covering the next 5 hours.
        let quotes = QuoteStore.load()
        let offset = QuoteOffsetStore.offset
        var entries: [QuoteEntry] = []
        var date = QuoteLibrary.slotStart(for: Date())

        for _ in 0 ..< 60 {
            entries.append(QuoteEntry(date: date, quote: QuoteLibrary.quote(at: date, offset: offset, from: quotes)))
            date = date.addingTimeInterval(QuoteLibrary.rotationInterval)
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct QuoteWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme

    var entry: QuoteEntry

    var body: some View {
        ZStack(alignment: .topLeading) {
            Text(verbatim: "\u{201C}")
                .font(.system(size: markSize, weight: .bold, design: .serif))
                .foregroundStyle(accentColor.opacity(0.18))
                .offset(x: -markSize * 0.06, y: -markSize * 0.42)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 0)

                Text(entry.quote.text)
                    .font(.system(size: quoteSize, weight: .medium, design: .serif))
                    .italic()
                    .foregroundStyle(primaryColor)
                    .lineSpacing(quoteSize * 0.22)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.6)
                    .lineLimit(lineLimit)
                    .fixedSize(horizontal: false, vertical: true)

                if !entry.quote.author.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Rectangle()
                            .fill(accentColor.opacity(0.45))
                            .frame(width: 24, height: 1)

                        Text(entry.quote.author.uppercased())
                            .font(.system(size: authorSize, weight: .semibold))
                            .tracking(1.2)
                            .foregroundStyle(secondaryColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .padding(.top, 12)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, showsControls ? 20 : 0)
        }
        .padding(.horizontal, 4)
        .overlay(alignment: .bottomTrailing) {
            if showsControls { controls }
        }
        .containerBackground(for: .widget) { background }
    }

    private var controls: some View {
        HStack(spacing: 2) {
            navigationButton(offset: -1, systemImage: "chevron.left", label: "Cita anterior")
            navigationButton(offset: 1, systemImage: "chevron.right", label: "Cita siguiente")
        }
        .buttonStyle(.plain)
        .foregroundStyle(secondaryColor)
    }

    private func navigationButton(offset: Int, systemImage: String, label: String) -> some View {
        Button(intent: ShiftQuoteIntent(offset: offset)) {
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .semibold))
                .frame(width: 24, height: 20)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(label)
    }

    private var showsControls: Bool {
        family != .systemSmall
    }

    private var background: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(red: 0.09, green: 0.10, blue: 0.13), Color(red: 0.05, green: 0.06, blue: 0.09)]
                : [Color(red: 0.99, green: 0.98, blue: 0.96), Color(red: 0.93, green: 0.92, blue: 0.90)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var primaryColor: Color {
        colorScheme == .dark ? Color(white: 0.95) : Color(white: 0.13)
    }

    private var secondaryColor: Color {
        colorScheme == .dark ? Color(white: 0.62) : Color(white: 0.40)
    }

    private var accentColor: Color {
        colorScheme == .dark
            ? Color(red: 0.76, green: 0.66, blue: 0.44)
            : Color(red: 0.55, green: 0.44, blue: 0.24)
    }

    private var quoteSize: CGFloat {
        switch family {
        case .systemSmall: 13
        case .systemLarge, .systemExtraLarge: 22
        default: 16
        }
    }

    private var authorSize: CGFloat {
        family == .systemSmall ? 8 : 10
    }

    private var markSize: CGFloat {
        switch family {
        case .systemSmall: 46
        case .systemLarge, .systemExtraLarge: 96
        default: 68
        }
    }

    private var lineLimit: Int {
        switch family {
        case .systemSmall: 6
        case .systemLarge, .systemExtraLarge: 12
        default: 5
        }
    }
}

struct widget: Widget {
    let kind: String = "widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            QuoteWidgetView(entry: entry)
        }
        .configurationDisplayName("Quotes")
        .description("A rotating quote every five minutes.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview("Medium", as: .systemMedium) {
    widget()
} timeline: {
    QuoteEntry(date: .now, quote: Quote(text: "I leave you the best of myself"))
    QuoteEntry(date: .now, quote: Quote(text: "The obstacle is the way", author: "Marcus Aurelius"))
}
