import SwiftUI
import UniformTypeIdentifiers

struct GameListView: View {
    @ObservedObject var viewModel: GameListViewModel
    let onGameSelected: (Game) -> Void

    @State private var showFilePicker = false
    @State private var pendingImportURL: URL?

    var body: some View {
        NavigationStack {
            List {
                libraryHeader
                    .listRowInsets(EdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                if viewModel.games.isEmpty {
                    emptyLibrary
                        .listRowInsets(EdgeInsets(top: 4, leading: 24, bottom: 24, trailing: 24))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(viewModel.games) { game in
                        GameRow(game: game) { onGameSelected(game) }
                            .listRowInsets(EdgeInsets(top: 5, leading: 24, bottom: 9, trailing: 24))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
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
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AveluneBackground())
            .toolbar(.hidden, for: .navigationBar)
            .task { await viewModel.refresh() }
            .sheet(isPresented: $showFilePicker, onDismiss: {
                guard let url = pendingImportURL else { return }
                pendingImportURL = nil
                Task { await viewModel.install(from: url) }
            }) {
                AveluneGamePicker { url in
                    pendingImportURL = url
                    showFilePicker = false
                }
            }
            .fullScreenCover(isPresented: Binding(
                get: { viewModel.installationStage != nil },
                set: { _ in }
            )) {
                InstallationView(stage: viewModel.installationStage ?? .preparing)
            }
            .overlay {
                if viewModel.isBusy && viewModel.installationStage == nil {
                    ProgressView("Mise à jour de la bibliothèque…")
                        .tint(AveluneTheme.lilac)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.black.opacity(0.6))
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

    private var libraryHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image("AveluneWordmark")
                .resizable()
                .scaledToFit()
                .frame(width: 245, height: 70, alignment: .leading)
                .offset(x: -22)
                .accessibilityLabel("Avelune")

            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("VOTRE UNIVERS")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(2.5)
                        .foregroundStyle(AveluneTheme.cyan)
                    Text("Bibliothèque")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Spacer()

                Button {
                    showFilePicker = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(AveluneTheme.background)
                        .frame(width: 46, height: 46)
                        .background(AveluneTheme.accent, in: Circle())
                }
                .accessibilityLabel("Importer un jeu")
            }

            Text(viewModel.games.isEmpty
                 ? "Vos aventures commencent ici."
                 : "\(viewModel.games.count) aventure\(viewModel.games.count > 1 ? "s" : "") à portée de main.")
                .font(.subheadline)
                .foregroundStyle(AveluneTheme.muted)
                .padding(.top, 3)
        }
        .padding(.bottom, 10)
    }

    private var emptyLibrary: some View {
        VStack(spacing: 20) {
            Image("AveluneMoon")
                .resizable()
                .scaledToFit()
                .frame(width: 190, height: 190)
                .shadow(color: AveluneTheme.lilac.opacity(0.22), radius: 36)
                .accessibilityHidden(true)

            VStack(spacing: 10) {
                Text("Un monde vous attend")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Importez votre premier jeu et retrouvez toutes vos aventures au même endroit.")
                    .font(.subheadline)
                    .foregroundStyle(AveluneTheme.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                showFilePicker = true
            } label: {
                Label("Importer un jeu", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(AvelunePrimaryButtonStyle())

            Text("Fichier .avelunegame")
                .font(.caption)
                .foregroundStyle(AveluneTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .background(AveluneTheme.surface, in: RoundedRectangle(cornerRadius: 30))
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(AveluneTheme.border))
    }
}

private struct InstallationView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var moonIsFloating = false

    let stage: InstallationStage

    var body: some View {
        ZStack {
            AveluneBackground()

            VStack(spacing: 18) {
                Image("AveluneMoon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .shadow(color: AveluneTheme.cyan.opacity(0.3), radius: 42)
                    .scaleEffect(moonIsFloating ? 1.05 : 0.96)
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                        value: moonIsFloating
                    )
                    .accessibilityHidden(true)

                Text("Une aventure arrive…")
                    .font(.system(size: 29, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(stage.message)
                    .font(.subheadline)
                    .foregroundStyle(AveluneTheme.muted)
                    .multilineTextAlignment(.center)
                    .id(stage)

                ProgressView()
                    .tint(AveluneTheme.cyan)
                    .scaleEffect(1.2)
                    .padding(.top, 12)
                    .accessibilityLabel(stage.message)

                HStack(spacing: 8) {
                    ForEach(InstallationStage.allCases, id: \.self) { step in
                        Capsule()
                            .fill(step.index <= stage.index ? AveluneTheme.accent : LinearGradient(
                                colors: [AveluneTheme.surfaceRaised, AveluneTheme.surfaceRaised],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(height: 5)
                    }
                }
                .frame(maxWidth: 210)
                .padding(.top, 20)

                Text("Gardez l’application ouverte pendant l’installation.")
                    .font(.caption)
                    .foregroundStyle(AveluneTheme.muted)
                    .padding(.top, 8)
            }
            .padding(32)
        }
        .interactiveDismissDisabled()
        .onAppear { moonIsFloating = !reduceMotion }
    }
}

private extension InstallationStage {
    static var allCases: [InstallationStage] { [.preparing, .installing, .finishing] }

    var index: Int {
        switch self {
        case .preparing: return 0
        case .installing: return 1
        case .finishing: return 2
        }
    }

    var message: String {
        switch self {
        case .preparing: return "Préparation du fichier de jeu"
        case .installing: return "Installation de votre jeu"
        case .finishing: return "Mise à jour de la bibliothèque"
        }
    }
}

private struct GameRow: View {
    let game: Game
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                GameArtwork(path: game.artworkPath)

                VStack(alignment: .leading, spacing: 5) {
                    Text(game.title)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AveluneTheme.muted)
                    if game.canContinue {
                        Label("Reprendre", systemImage: "play.fill")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(AveluneTheme.cyan)
                    }
                }

                Spacer()

                Image(systemName: "play.fill")
                    .font(.caption)
                    .foregroundStyle(AveluneTheme.background)
                    .frame(width: 34, height: 34)
                    .background(AveluneTheme.accent, in: Circle())
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AveluneTheme.surface, in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(AveluneTheme.border))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Jouer à \(game.title)")
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
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(AveluneTheme.lilac)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AveluneTheme.surfaceRaised)
            }
        }
        .frame(width: 76, height: 76)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
