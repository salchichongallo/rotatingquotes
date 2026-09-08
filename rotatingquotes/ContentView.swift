//
//  ContentView.swift
//  rotatingquotes
//
//  Created by Jaime Gallo on 8/09/26.
//

import SwiftUI

struct ContentView: View {
    @State private var model = QuotesModel()

    var body: some View {
        VStack(spacing: 0) {
            List {
                ForEach($model.quotes) { $quote in
                    QuoteRow(quote: $quote) {
                        model.remove(quote)
                    }
                }
                .onDelete { model.remove(atOffsets: $0) }
                .onMove { model.move(fromOffsets: $0, toOffset: $1) }
            }
            .listStyle(.inset)

            Divider()

            HStack(spacing: 12) {
                Button {
                    model.add()
                } label: {
                    Label("Añadir frase", systemImage: "plus")
                }

                Button("Restaurar predeterminadas") {
                    model.restoreDefaults()
                }

                Spacer()

                Text(footerText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
        }
        .frame(minWidth: 520, minHeight: 380)
        .onChange(of: model.quotes) {
            model.scheduleSave()
        }
    }

    private var footerText: String {
        let count = model.quotes.count
        let minutes = count * 5
        return "\(count) frases · ciclo completo de \(minutes) min · \(model.status)"
    }
}

private struct QuoteRow: View {
    @Binding var quote: Quote
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                TextField("Frase", text: $quote.text, axis: .vertical)
                    .lineLimit(1 ... 4)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .serif))

                TextField("Autor (opcional)", text: $quote.author)
                    .textFieldStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help("Eliminar frase")
            .opacity(isHovering ? 1 : 0)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .contextMenu {
            Button("Eliminar frase", role: .destructive, action: onDelete)
        }
    }
}

#Preview {
    ContentView()
}
