import SwiftUI
import UniformTypeIdentifiers

struct GameListView: View {
    @ObservedObject var viewModel: GameListViewModel
    let onGameSelected: (Game) -> Void

    @State private var showFilePicker = false
    @State private var pendingImportURL: URL?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                libraryHeader

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        if viewModel.games.isEmpty {
                            emptyLibrary
                        } else {
                            HStack {
                                Text("VOS AVENTURES")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .tracking(2.2)
                                    .foregroundStyle(AveluneTheme.muted)

                                Spacer()

                                Text("\(viewModel.games.count)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(AveluneTheme.cyan)
                            }
                            .padding(.horizontal, 4)

                            ForEach(viewModel.games) { game in
                                GameRow(
                                    game: game,
                                    onPlay: { onGameSelected(game) },
                                    onDelete: { Task { await viewModel.uninstall(game) } }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 22)
                    .padding(.bottom, 36)
                }
                .scrollIndicators(.hidden)
            }
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
                InstallationView(
                    stage: viewModel.installationStage ?? .preparing,
                    gameName: viewModel.installationName ?? "Nouveau jeu"
                )
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
                .frame(width: 205, height: 58, alignment: .leading)
                .offset(x: -18)
                .accessibilityLabel("Avelune")

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("VOTRE UNIVERS")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(2.5)
                        .foregroundStyle(AveluneTheme.cyan)
                    Text("Bibliothèque")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                Spacer()

                Button {
                    showFilePicker = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(width: 34, height: 34)
                }
                .aveluneGlassButton(circular: true)
                .accessibilityLabel("Importer un jeu")
            }

            Text(viewModel.games.isEmpty
                 ? "Vos aventures commencent ici."
                 : "\(viewModel.games.count) aventure\(viewModel.games.count > 1 ? "s" : "") à portée de main.")
                .font(.subheadline)
                .foregroundStyle(AveluneTheme.muted)
                .padding(.top, 3)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            LinearGradient(
                colors: [AveluneTheme.surface.opacity(0.9), AveluneTheme.background.opacity(0.96)],
                startPoint: .top,
                endPoint: .bottom
            )
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
                            .foregroundStyle(.white)
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
                                .foregroundStyle(.white)

                            Spacer()

                            Text("\(stage.index + 1) / 3")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(AveluneTheme.muted)
                        }

                        HStack(spacing: 6) {
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
                                }
                                .accessibilityElement(children: .combine)
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

private struct GameRow: View {
    let game: Game
    let onPlay: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .bottomLeading) {
                GameArtwork(path: game.artworkPath)

                LinearGradient(
                    colors: [.clear, AveluneTheme.background.opacity(0.28), AveluneTheme.background.opacity(0.96)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text(game.canContinue ? "CONTINUER À JOUER" : "VOTRE AVENTURE")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.8)
                        .foregroundStyle(AveluneTheme.cyan)

                    Spacer()

                    Text(game.title)
                        .font(.system(size: 27, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 2)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.78))
                        .lineLimit(1)
                }
                .padding(22)
            }
            .frame(height: 210)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .onTapGesture(perform: onPlay)
            .accessibilityLabel("Jouer à \(game.title)")
            .accessibilityAddTraits(.isButton)

            HStack {
                Menu {
                    Button(role: .destructive, action: onDelete) {
                        Label("Supprimer le jeu", systemImage: "trash")
                    }
                } label: {
                    Label("Options", systemImage: "ellipsis")
                        .font(.subheadline.weight(.semibold))
                }
                .aveluneGlassButton()
                .accessibilityLabel("Options pour \(game.title)")

                Spacer()

                Button(action: onPlay) {
                    Label(game.canContinue ? "Reprendre" : "Jouer", systemImage: "play.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .aveluneGlassButton(prominent: true)
                .accessibilityLabel("Jouer à \(game.title)")
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(
                    colors: [AveluneTheme.surfaceRaised, AveluneTheme.surface],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(AveluneTheme.border, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.16), radius: 20, y: 10)
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
        GeometryReader { geometry in
            Group {
                if let path, let image = UIImage(contentsOfFile: path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        LinearGradient(
                            colors: [AveluneTheme.lilac.opacity(0.54), AveluneTheme.surfaceRaised, AveluneTheme.cyan.opacity(0.34)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        Circle()
                            .fill(AveluneTheme.cyan.opacity(0.25))
                            .frame(width: 210, height: 210)
                            .blur(radius: 42)
                            .offset(x: 115, y: -65)

                        Image(systemName: "sparkles")
                            .font(.system(size: 78, weight: .ultraLight))
                            .foregroundStyle(.white.opacity(0.65))
                            .offset(x: 80, y: -15)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
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
