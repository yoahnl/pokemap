import SwiftUI
import UniformTypeIdentifiers

struct GameListView: View {
    @ObservedObject var viewModel: GameListViewModel
    let onGameSelected: (Game) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var artworkTransition
    @State private var path: [String] = []
    @State private var quickViewGame: Game?
    @State private var showFilePicker = false
    @State private var pendingImportURL: URL?

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                VStack(spacing: 0) {
                    libraryHeader

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 26) {
                            if viewModel.games.isEmpty {
                                emptyLibrary
                                    .padding(.horizontal, 24)
                            } else {
                                FeaturedGamesView(
                                    games: Game.featuredOrder(viewModel.games),
                                    onPlay: onGameSelected,
                                    onDetails: showDetails,
                                    onQuickView: showQuickView
                                )

                                GameCollectionView(
                                    games: viewModel.games,
                                    transition: artworkTransition,
                                    onDetails: showDetails,
                                    onQuickView: showQuickView,
                                    onDelete: { game in Task { await viewModel.uninstall(game) } },
                                    onImport: { showFilePicker = true }
                                )
                                .padding(.horizontal, 24)
                            }
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 36)
                    }
                    .scrollIndicators(.hidden)
                }
                .background(AveluneBackground())

                if let game = quickViewGame {
                    QuickGameView(
                        game: game,
                        transition: artworkTransition,
                        reduceMotion: reduceMotion,
                        onClose: closeQuickView,
                        onPlay: {
                            closeQuickView()
                            onGameSelected(game)
                        },
                        onDetails: {
                            quickViewGame = nil
                            DispatchQueue.main.async {
                                path.append(game.id)
                            }
                        }
                    )
                    .zIndex(1)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { id in
                if let game = viewModel.games.first(where: { $0.id == id }) {
                    GameDetailView(game: game, onPlay: { onGameSelected(game) })
                }
            }
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
                InstallationView(
                    stage: viewModel.installationStage ?? .preparing,
                    gameName: viewModel.installationName ?? "Nouveau jeu"
                )
            }
            .overlay {
                if viewModel.isBusy && viewModel.installationStage == nil {
                    ProgressView("Mise à jour de la bibliothèque…")
                        .tint(AveluneTheme.lilac)
                        .foregroundStyle(AveluneTheme.text)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial)
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

    private func showDetails(_ game: Game) { path.append(game.id) }

    private func showQuickView(_ game: Game) {
        withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.42, dampingFraction: 0.86)) {
            quickViewGame = game
        }
    }

    private func closeQuickView() {
        withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.38, dampingFraction: 0.88)) {
            quickViewGame = nil
        }
    }

    private var libraryHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image("AveluneMoon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 43, height: 43)
                    .clipShape(RoundedRectangle(cornerRadius: 11))
                    .accessibilityHidden(true)

                Image("AveluneWordmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 46, alignment: .leading)
                    .shadow(color: AveluneTheme.text.opacity(0.32), radius: 1.5)
                    .accessibilityLabel("Avelune")

                Spacer()

                Button { showFilePicker = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 19, weight: .semibold))
                        .frame(width: 44, height: 44)
                }
                .aveluneGlassButton(circular: true)
                .accessibilityLabel("Importer un jeu")
            }

            Text("Bibliothèque")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(AveluneTheme.text)

            Text(viewModel.games.isEmpty ? "Vos aventures commencent ici." : "\(viewModel.games.count) aventure\(viewModel.games.count > 1 ? "s" : "")")
                .font(.subheadline)
                .foregroundStyle(AveluneTheme.muted)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            AveluneTheme.background
            .ignoresSafeArea(edges: .top)
        }
        .overlay(alignment: .bottom) {
            AveluneTheme.border.frame(height: 1)
        }
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
                    .foregroundStyle(AveluneTheme.text)

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
                    .font(.system(.headline, design: .rounded))
                    .frame(maxWidth: .infinity)
            }
            .aveluneGlassButton(prominent: true)

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
    @State private var isOrbiting = false

    let stage: InstallationStage
    let gameName: String

    var body: some View {
        ZStack {
            AveluneBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    HStack {
                        Image("AveluneWordmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 170, height: 50, alignment: .leading)
                            .offset(x: -14)
                            .accessibilityLabel("Avelune")

                        Spacer()

                        Text("INSTALLATION")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(2)
                            .foregroundStyle(AveluneTheme.cyan)
                    }

                    installationArtwork
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Une nouvelle aventure arrive")
                            .font(.system(size: 29, weight: .bold, design: .rounded))
                            .foregroundStyle(AveluneTheme.text)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(gameName)
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .foregroundStyle(AveluneTheme.cyan)
                            .lineLimit(2)

                        Text(stage.detail)
                            .font(.subheadline)
                            .foregroundStyle(AveluneTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                            .id(stage)
                            .transition(.opacity.combined(with: .offset(y: 8)))
                    }
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: stage)

                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            ProgressView()
                                .tint(AveluneTheme.cyan)

                            Text(stage.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AveluneTheme.text)

                            Spacer()

                            Text("Étape \(stage.index + 1) sur 3")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(AveluneTheme.muted)
                        }

                        HStack(spacing: 6) {
                            ForEach(InstallationStage.allCases, id: \.self) { step in
                                Capsule()
                                    .fill(step.index < stage.index ? AveluneTheme.accent : LinearGradient(
                                        colors: [AveluneTheme.surfaceRaised, AveluneTheme.surfaceRaised],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                                    .frame(height: 5)
                                    .overlay {
                                        if step == stage {
                                            Capsule()
                                                .strokeBorder(AveluneTheme.cyan, lineWidth: 1)
                                        }
                                    }
                            }
                        }
                        .animation(reduceMotion ? nil : .smooth(duration: 0.45), value: stage)

                        VStack(spacing: 14) {
                            ForEach(InstallationStage.allCases, id: \.self) { step in
                                HStack(spacing: 13) {
                                    Image(systemName: step.index < stage.index ? "checkmark.circle.fill" : step.symbol)
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundStyle(step.index <= stage.index ? AveluneTheme.cyan : AveluneTheme.muted)
                                        .frame(width: 25)

                                    Text(step.title)
                                        .font(.subheadline.weight(step == stage ? .semibold : .regular))
                                        .foregroundStyle(step.index <= stage.index ? .white : AveluneTheme.muted)

                                    Spacer()

                                    if step == stage {
                                        Text("En cours")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(AveluneTheme.cyan)
                                            .accessibilityHidden(true)
                                    }
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityValue(step.index < stage.index ? "Terminée" : step == stage ? "En cours" : "À venir")
                            }
                        }
                    }
                    .padding(20)
                    .background(AveluneTheme.surface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .strokeBorder(AveluneTheme.border, lineWidth: 1)
                    }

                    Label("Gardez Avelune ouverte pendant l’installation.", systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(AveluneTheme.muted)
                }
                .padding(.horizontal, 26)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .interactiveDismissDisabled()
        .onAppear { isOrbiting = !reduceMotion }
    }

    private var installationArtwork: some View {
        ZStack {
            Circle()
                .strokeBorder(AveluneTheme.border, lineWidth: 1)
                .frame(width: 158, height: 158)

            Circle()
                .trim(from: 0.02, to: 0.3)
                .stroke(AveluneTheme.accent, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 158, height: 158)
                .rotationEffect(.degrees(isOrbiting ? 360 : 0))
                .animation(reduceMotion ? nil : .linear(duration: 9).repeatForever(autoreverses: false), value: isOrbiting)

            installationTile
        }
        .frame(height: 166)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var installationTile: some View {
        let tile = Image(systemName: "square.stack.3d.up.fill")
            .font(.system(size: 42, weight: .light))
            .foregroundStyle(AveluneTheme.accent)
            .frame(width: 116, height: 116)

        if #available(iOS 26.0, *) {
            tile.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        } else {
            tile.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        }
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

    var title: String {
        switch self {
        case .preparing: return "Préparation du fichier"
        case .installing: return "Installation du jeu"
        case .finishing: return "Actualisation de la bibliothèque"
        }
    }

    var detail: String {
        switch self {
        case .preparing: return "Copie de votre fichier dans Avelune."
        case .installing: return "Avelune ajoute votre jeu à la bibliothèque."
        case .finishing: return "Vos aventures se préparent à être lancées."
        }
    }

    var symbol: String {
        switch self {
        case .preparing: return "doc.zipper"
        case .installing: return "square.stack.3d.up"
        case .finishing: return "checkmark.seal"
        }
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
