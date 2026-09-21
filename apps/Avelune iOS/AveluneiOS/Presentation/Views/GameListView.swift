import SwiftUI
import UniformTypeIdentifiers

struct GameListView: View {
    @ObservedObject var viewModel: GameListViewModel
    let onGameSelected: (Game) -> Void

    @State private var showFilePicker = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.games.isEmpty {
                    ContentUnavailableView(
                        "Aucun jeu",
                        systemImage: "gamecontroller",
                        description: Text("Importez un fichier .avelunegame pour commencer.")
                    )
                } else {
                    List {
                        ForEach(viewModel.games) { game in
                            GameRow(game: game) { onGameSelected(game) }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        Task { await viewModel.uninstall(game) }
                                    } label: {
                                        Label("Supprimer", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .navigationTitle("Mes Jeux")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showFilePicker = true
                    } label: {
                        Label("Importer", systemImage: "plus")
                    }
                }
            }
            .task { await viewModel.refresh() }
            .sheet(isPresented: $showFilePicker) {
                AveluneGamePicker { url in
                    guard let localPath = Self.copyToLocal(url: url) else { return }
                    Task {
                        await viewModel.install(packagePath: localPath)
                        try? FileManager.default.removeItem(atPath: localPath)
                    }
                }
            }
            .overlay {
                if viewModel.isBusy {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.black.opacity(0.3))
                }
            }
            .alert("Erreur", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }

    static func copyToLocal(url: URL) -> String? {
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent(url.lastPathComponent)
        try? FileManager.default.removeItem(at: destination)

        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        do {
            try FileManager.default.copyItem(at: url, to: destination)
            return destination.path
        } catch {
            return nil
        }
    }
}

private struct GameRow: View {
    let game: Game
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                GameArtwork(path: game.artworkPath)

                VStack(alignment: .leading, spacing: 2) {
                    Text(game.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if game.canContinue {
                        Text("Partie en cours")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private var subtitle: String {
        [game.author, game.version.map { "v\($0)" }]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
}

private struct GameArtwork: View {
    let path: String?

    var body: some View {
        Group {
            if let path, let image = UIImage(contentsOfFile: path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "gamecontroller.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.blue.opacity(0.1))
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct AveluneGamePicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let type = UTType(filenameExtension: "avelunegame") ?? .data
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [type])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ controller: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void

        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}
