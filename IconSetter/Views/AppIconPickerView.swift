import SwiftUI

/// Searchable grid of the icons of every app on this Mac.
struct AppIconPickerView: View {
    @Environment(AppModel.self) private var model
    @State private var query = ""

    private let columns = [GridItem(.adaptive(minimum: 96, maximum: 120), spacing: 8)]

    private var filteredApps: [AppEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return model.apps }
        return model.apps.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                TextField("Search apps", text: $query, prompt: Text("Search apps"))
                    .textFieldStyle(.roundedBorder)
                Button("Other App…") { model.presentAppPanel() }
            }
            .padding(10)
            Divider()

            if model.isLoadingApps {
                ProgressView("Finding apps…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredApps.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(filteredApps) { app in
                            AppCell(app: app, isSelected: app == model.selectedApp) {
                                model.selectedApp = app
                            }
                        }
                    }
                    .padding(10)
                }
            }

            Divider()
            HStack {
                if let app = model.selectedApp {
                    Text(app.name).font(.callout)
                    Text(app.url.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                } else {
                    Text("Select an app to use its icon.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(filteredApps.count == 1 ? "1 app" : "\(filteredApps.count) apps")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.bar)
        }
    }
}

private struct AppCell: View {
    @Environment(AppModel.self) private var model
    let app: AppEntry
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(nsImage: model.icon(forApp: app))
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 64, height: 64)
                Text(app.name)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 28, alignment: .top)
            }
            .padding(6)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.25) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(app.url.path)
    }
}
