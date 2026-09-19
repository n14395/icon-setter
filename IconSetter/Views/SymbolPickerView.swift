import SwiftUI

/// Searchable, filterable grid of every SF Symbol on this Mac.
struct SymbolPickerView: View {
    @Environment(AppModel.self) private var model
    @Binding var selection: String

    @State private var query = ""
    @State private var category: String?
    @State private var results: [SFSymbol] = []

    private let columns = [GridItem(.adaptive(minimum: 54, maximum: 64), spacing: 6)]

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            if model.isLoadingSymbols {
                ProgressView("Loading symbols…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if results.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                grid
            }
            Divider()
            footer
        }
        .task(id: searchKey) { await runSearch() }
    }

    private var searchKey: String {
        "\(query)|\(category ?? "")|\(model.symbolCatalog.symbols.count)"
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            TextField("Search symbols", text: $query, prompt: Text("Search symbols"))
                .textFieldStyle(.roundedBorder)
            Picker("Category", selection: $category) {
                Text("All Categories").tag(String?.none)
                Divider()
                ForEach(model.symbolCatalog.categories) { category in
                    Label(category.label, systemImage: category.systemImage).tag(String?.some(category.key))
                }
            }
            .labelsHidden()
            .frame(width: 180)
        }
        .padding(10)
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(results) { symbol in
                    SymbolCell(name: symbol.name, isSelected: symbol.name == selection) {
                        selection = symbol.name
                    }
                }
            }
            .padding(10)
        }
    }

    private var footer: some View {
        HStack {
            Image(systemName: selection)
            Text(selection)
                .font(.callout.monospaced())
                .textSelection(.enabled)
            Spacer()
            Text(results.count == 1 ? "1 symbol" : "\(results.count) symbols")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func runSearch() async {
        let catalog = model.symbolCatalog
        let query = query
        let category = category
        if !query.isEmpty {
            // Let typing settle before searching ten thousand names.
            try? await Task.sleep(for: .milliseconds(120))
            if Task.isCancelled { return }
        }
        let found = await Task.detached(priority: .userInitiated) {
            catalog.search(query, category: category)
        }.value
        if !Task.isCancelled { results = found }
    }
}

private struct SymbolCell: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 22))
                .frame(width: 54, height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.accentColor.opacity(0.25) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(name)
    }
}
