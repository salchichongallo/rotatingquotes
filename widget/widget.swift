//
//  widget.swift
//  widget
//
//  Created by Jimmy Murillo on 8/09/26.
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
        ZStack(alignment: .bottomTrailing) {
            Text(verbatim: "\u{201C}")
                .font(.system(size: markSize, weight: .black, design: .serif))
                .foregroundStyle(markGradient)
                .offset(x: markSize * 0.08, y: markSize * 0.30)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                Text(entry.quote.text)
                    .font(.system(size: quoteSize, weight: .semibold, design: .serif))
                    .italic()
                    .foregroundStyle(primaryColor)
                    .lineSpacing(quoteSize * 0.18)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.35)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

                if !entry.quote.author.isEmpty {
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(accentColor)
                            .frame(width: 18, height: 2)

                        Text(entry.quote.author.uppercased())
                            .font(.system(size: authorSize, weight: .bold))
                            .tracking(1.6)
                            .foregroundStyle(accentColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .padding(.top, 10)
                }
            }
            .padding(padding)
            .padding(.bottom, showsControls ? 16 : 0)
        }
        .overlay(alignment: .bottomTrailing) {
            if showsControls {
                controls.padding(padding * 0.6)
            }
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
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.13, green: 0.14, blue: 0.19), Color(red: 0.04, green: 0.04, blue: 0.07)]
                    : [Color(red: 1.00, green: 0.99, blue: 0.97), Color(red: 0.89, green: 0.87, blue: 0.83)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [accentColor.opacity(colorScheme == .dark ? 0.22 : 0.14), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 260
            )
        }
    }

    private var markGradient: LinearGradient {
        LinearGradient(
            colors: [accentColor.opacity(colorScheme == .dark ? 0.30 : 0.24), accentColor.opacity(0.04)],
            startPoint: .top,
            endPoint: .bottom
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
        case .systemSmall: 17
        case .systemLarge, .systemExtraLarge: 34
        default: 23
        }
    }

    private var authorSize: CGFloat {
        switch family {
        case .systemSmall: 8
        case .systemLarge, .systemExtraLarge: 12
        default: 10
        }
    }

    private var markSize: CGFloat {
        switch family {
        case .systemSmall: 96
        case .systemLarge, .systemExtraLarge: 230
        default: 150
        }
    }

    private var padding: CGFloat {
        switch family {
        case .systemSmall: 14
        case .systemLarge, .systemExtraLarge: 26
        default: 20
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
        .contentMarginsDisabled()
    }
}

#Preview("Medium", as: .systemMedium) {
    widget()
} timeline: {
    QuoteEntry(date: .now, quote: Quote(text: "I leave you the best of myself"))
    QuoteEntry(date: .now, quote: Quote(text: "The obstacle is the way", author: "Marcus Aurelius"))
}
