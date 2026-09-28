import SwiftUI
import UniformTypeIdentifiers

struct GameListView: View {
    @ObservedObject var viewModel: GameListViewModel
    let onGameSelected: (Game) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var navigationTransition
    @Namespace private var quickTransition
    @State private var path: [String] = []
    @State private var navigationSourceID: String?
    @State private var quickViewGame: Game?
    @State private var quickViewSourceID: String?
    @State private var showFilePicker = false
    @State private var pendingImportURL: URL?

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 26) {
                    if viewModel.libraryState == .loading {
                        LibraryLoadingView()
                            .padding(.horizontal, 24)
                    } else if viewModel.libraryState == .failed {
                        failedLibrary
                            .padding(.horizontal, 24)
                    } else {
                        Text(viewModel.games.isEmpty ? "Vos aventures commencent ici." : "\(viewModel.games.count) aventure\(viewModel.games.count > 1 ? "s" : "")")
                            .font(.subheadline)
                            .foregroundStyle(AveluneTheme.muted)
                            .padding(.horizontal, 24)
                    }

                    if viewModel.libraryState == .loaded && viewModel.games.isEmpty {
                        emptyLibrary
                            .padding(.horizontal, 24)
                    } else if viewModel.libraryState == .loaded {
                        FeaturedGamesView(
                            games: Game.featuredOrder(viewModel.games),
                            navigationTransition: navigationTransition,
                            quickTransition: quickTransition,
                            onPlay: onGameSelected,
                            onDetails: { showDetails($0, sourceID: "featured:\($0.id)") },
                            onQuickView: { showQuickView($0, sourceID: "featured:\($0.id)") }
                        )

                        GameCollectionView(
                            games: viewModel.games,
                            navigationTransition: navigationTransition,
                            quickTransition: quickTransition,
                            onDetails: { showDetails($0, sourceID: "collection:\($0.id)") },
                            onQuickView: { showQuickView($0, sourceID: "collection:\($0.id)") },
                            onDelete: { game in Task { await viewModel.uninstall(game) } },
                            onImport: { showFilePicker = true }
                        )
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 36)
            }
            .scrollIndicators(.hidden)
            .accessibilityIdentifier("library-scroll")
            .background(AveluneBackground())
            .overlay {
                if let game = quickViewGame {
                    QuickGameView(
                        game: game,
                        transition: quickTransition,
                        sourceID: quickViewSourceID ?? "collection:\(game.id)",
                        reduceMotion: reduceMotion,
                        onClose: closeQuickView,
                        onPlay: {
                            closeQuickView()
                            onGameSelected(game)
                        },
                        onDetails: {
                            navigationSourceID = quickViewSourceID
                            path.append(game.id)
                            quickViewGame = nil
                        }
                    )
                }
            }
            .navigationTitle("Bibliothèque")
            .navigationBarTitleDisplayMode(.large)
            .toolbar(quickViewGame == nil ? .visible : .hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image("AveluneMoon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .accessibilityLabel("Avelune")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button { showFilePicker = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Importer un jeu")
                }
            }
            .navigationDestination(for: String.self) { id in
                if let game = viewModel.games.first(where: { $0.id == id }) {
                    GameDetailView(game: game, onPlay: { onGameSelected(game) })
                        .aveluneZoomDestination(
                            id: navigationSourceID ?? "featured:\(game.id)",
                            in: navigationTransition,
                            reduceMotion: reduceMotion
                        )
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

    private func showDetails(_ game: Game, sourceID: String) {
        navigationSourceID = sourceID
        path.append(game.id)
    }

    private func showQuickView(_ game: Game, sourceID: String) {
        quickViewSourceID = sourceID
        withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.42, dampingFraction: 0.86)) {
            quickViewGame = game
        }
    }

    private func closeQuickView() {
        withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.38, dampingFraction: 0.88)) {
            quickViewGame = nil
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

    private var failedLibrary: some View {
        VStack(spacing: 18) {
            Image("AveluneMoon")
                .resizable()
                .scaledToFit()
                .frame(width: 104, height: 104)
                .accessibilityHidden(true)

            Text("La bibliothèque ne s’ouvre pas")
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .foregroundStyle(AveluneTheme.text)

            Text("Impossible de retrouver vos jeux pour le moment. Réessayons.")
                .font(.subheadline)
                .foregroundStyle(AveluneTheme.muted)
                .multilineTextAlignment(.center)

            if let detail = viewModel.libraryLoadError {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(AveluneTheme.muted)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }

            Button {
                Task { await viewModel.refresh() }
            } label: {
                Label("Réessayer", systemImage: "arrow.clockwise")
                    .font(.system(.headline, design: .rounded))
                    .frame(maxWidth: .infinity)
            }
            .aveluneGlassButton(prominent: true)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(AveluneTheme.surface, in: RoundedRectangle(cornerRadius: 30))
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(AveluneTheme.border))
        .accessibilityIdentifier("library-load-failed")
    }
}

private struct LibraryLoadingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isOrbiting = false

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AveluneTheme.lilac.opacity(0.28), AveluneTheme.cyan.opacity(0.12), .clear],
                            center: .center,
                            startRadius: 12,
                            endRadius: 125
                        )
                    )
                    .frame(width: 250, height: 250)

                Circle()
                    .stroke(AveluneTheme.border, lineWidth: 1)
                    .frame(width: 214, height: 214)

                Circle()
                    .trim(from: 0.03, to: 0.42)
                    .stroke(
                        AngularGradient(
                            colors: [AveluneTheme.rose, AveluneTheme.lilac, AveluneTheme.cyan, AveluneTheme.mint],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 214, height: 214)
                    .rotationEffect(.degrees(isOrbiting ? 360 : 0))
                    .animation(reduceMotion ? nil : .linear(duration: 7).repeatForever(autoreverses: false), value: isOrbiting)

                Circle()
                    .trim(from: 0.48, to: 0.82)
                    .stroke(
                        AngularGradient(
                            colors: [AveluneTheme.cyan, AveluneTheme.mint, AveluneTheme.rose],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                    )
                    .frame(width: 176, height: 176)
                    .rotationEffect(.degrees(isOrbiting ? -360 : 0))
                    .animation(reduceMotion ? nil : .linear(duration: 10).repeatForever(autoreverses: false), value: isOrbiting)

                Image("AveluneMoon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 136, height: 136)
                    .shadow(color: AveluneTheme.lilac.opacity(0.25), radius: 20)

                Circle()
                    .fill(AveluneTheme.rose)
                    .frame(width: 7, height: 7)
                    .offset(x: -110, y: -50)

                Circle()
                    .fill(AveluneTheme.mint)
                    .frame(width: 5, height: 5)
                    .offset(x: 111, y: 48)
            }
            .frame(height: 260)

            Text("Vos mondes se rassemblent")
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .foregroundStyle(AveluneTheme.text)
                .multilineTextAlignment(.center)

            Text("On prépare votre bibliothèque…")
                .font(.subheadline)
                .foregroundStyle(AveluneTheme.muted)
                .multilineTextAlignment(.center)

            Capsule()
                .fill(AveluneTheme.accent)
                .frame(width: 78, height: 3)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 42)
        .onAppear { isOrbiting = !reduceMotion }
        .onChange(of: reduceMotion) { _, isReduced in isOrbiting = !isReduced }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Chargement de la bibliothèque Avelune")
        .accessibilityIdentifier("library-loading")
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
