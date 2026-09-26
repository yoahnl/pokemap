import ImageIO
import SwiftUI

@MainActor
final class LibraryArtworkCache {
    static let shared = LibraryArtworkCache()

    private let images = NSCache<NSString, UIImage>()

    private init() {
        images.countLimit = 80
    }

    func image(for paths: [String], maxPixelSize: Int) async -> UIImage? {
        for path in paths {
            let key = "\(path):\(maxPixelSize)" as NSString
            if let image = images.object(forKey: key) { return image }

            let image = await Task.detached(priority: .utility) {
                let url = URL(fileURLWithPath: path)
                guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                      let thumbnail = CGImageSourceCreateThumbnailAtIndex(
                        source,
                        0,
                        [
                            kCGImageSourceCreateThumbnailFromImageAlways: true,
                            kCGImageSourceCreateThumbnailWithTransform: true,
                            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
                        ] as CFDictionary
                      ) else { return nil as UIImage? }
                return UIImage(cgImage: thumbnail)
            }.value

            if let image {
                images.setObject(image, forKey: key)
                return image
            }
        }
        return nil
    }
}

struct LibraryArtwork: View {
    let paths: [String]

    @State private var image: UIImage?

    var body: some View {
        GeometryReader { geometry in
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        LinearGradient(
                            colors: [
                                AveluneTheme.lilac.opacity(0.5),
                                AveluneTheme.surfaceRaised,
                                AveluneTheme.cyan.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        Image(systemName: "sparkles")
                            .font(.system(size: 58, weight: .ultraLight))
                            .foregroundStyle(AveluneTheme.text.opacity(0.65))
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
            .task(id: paths) {
                image = nil
                image = await LibraryArtworkCache.shared.image(
                    for: paths,
                    maxPixelSize: max(600, Int(max(geometry.size.width, geometry.size.height) * 3))
                )
            }
        }
        .accessibilityHidden(true)
    }
}

struct FeaturedGamesView: View {
    let games: [Game]
    let onPlay: (Game) -> Void
    let onDetails: (Game) -> Void
    let onQuickView: (Game) -> Void

    @State private var selectedID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("À la une")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(AveluneTheme.text)
                .padding(.horizontal, 24)

            GeometryReader { geometry in
                let cardWidth = min(geometry.size.width - 64, 600)

                ScrollView(.horizontal) {
                    LazyHStack(spacing: 12) {
                        ForEach(games) { game in
                            FeaturedGameCard(
                                game: game,
                                onPlay: { onPlay(game) },
                                onDetails: { onDetails(game) }
                            )
                            .frame(width: cardWidth)
                            .id(game.id)
                            .onLongPressGesture { onQuickView(game) }
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal, (geometry.size.width - cardWidth) / 2)
                }
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $selectedID)
                .accessibilityIdentifier("featured-carousel")
            }
            .frame(height: 292)

            if games.count > 1 {
                HStack(spacing: 7) {
                    ForEach(games) { game in
                        Capsule()
                            .fill((selectedID ?? games[0].id) == game.id ? AveluneTheme.lilac : AveluneTheme.muted.opacity(0.35))
                            .frame(width: (selectedID ?? games[0].id) == game.id ? 18 : 7, height: 7)
                    }
                }
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Jeu \(currentPage + 1) sur \(games.count)")
                .accessibilityValue("\(currentPage + 1)")
                .accessibilityIdentifier("featured-page-count")
            }
        }
    }

    private var currentPage: Int {
        games.firstIndex { $0.id == selectedID } ?? 0
    }
}

private struct FeaturedGameCard: View {
    let game: Game
    let onPlay: () -> Void
    let onDetails: () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LibraryArtwork(paths: game.heroCandidates)

            LinearGradient(
                colors: [.clear, .black.opacity(0.34), .black.opacity(0.88)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 12) {
                Spacer()
                Text(game.title)
                    .font(.system(.title, design: .serif, weight: .bold))
                    .lineLimit(2)

                if !game.author.isEmpty {
                    Text(game.author)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                }

                HStack(spacing: 10) {
                    Button(action: onPlay) {
                        Label(game.canContinue ? "Reprendre" : "Jouer", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AveluneTheme.lilac)

                    Button(action: onDetails) {
                        Label("Détails", systemImage: "info.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                }
                .controlSize(.large)
            }
            .padding(20)
            .foregroundStyle(.white)
        }
        .frame(height: 292)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(AveluneTheme.border))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(game.title)
    }
}

struct GameCollectionView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let games: [Game]
    let transition: Namespace.ID
    let onDetails: (Game) -> Void
    let onQuickView: (Game) -> Void
    let onDelete: (Game) -> Void
    let onImport: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 145, maximum: 210), spacing: 14)]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Ma collection")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(AveluneTheme.text)

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(games) { game in
                    collectionCard(game)
                }

                Button(action: onImport) {
                    VStack(spacing: 12) {
                        Image(systemName: "plus")
                            .font(.system(size: 25, weight: .light))
                            .frame(width: 58, height: 58)
                            .background(AveluneTheme.lilac.opacity(0.14), in: Circle())
                        Text("Ajouter un jeu")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(AveluneTheme.text)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aspectRatio(0.72, contentMode: .fit)
                    .background(AveluneTheme.surface.opacity(0.5), in: RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(AveluneTheme.border, style: StrokeStyle(lineWidth: 1, dash: [5])))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Importer un jeu")
            }
        }
    }

    private func collectionCard(_ game: Game) -> some View {
        ZStack(alignment: .topTrailing) {
            ZStack(alignment: .bottomLeading) {
                LibraryArtwork(paths: game.coverCandidates)

                LinearGradient(
                    colors: [.clear, .black.opacity(0.1), .black.opacity(0.84)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Text(game.title)
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .padding(12)
            }
            .aspectRatio(0.72, contentMode: .fit)
            .background {
                if !reduceMotion {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(AveluneTheme.surface)
                        .matchedGeometryEffect(id: game.id, in: transition)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(AveluneTheme.border))
            .contentShape(RoundedRectangle(cornerRadius: 20))
            .onTapGesture { onDetails(game) }
            .onLongPressGesture { onQuickView(game) }
            .accessibilityLabel("\(game.title), voir la fiche")
            .accessibilityAddTraits(.isButton)

            Menu {
                Button("Voir la fiche", systemImage: "info.circle") { onDetails(game) }
                Button(role: .destructive) { onDelete(game) } label: {
                    Label("Supprimer le jeu", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.black.opacity(0.45), in: Circle())
            }
            .padding(8)
            .accessibilityLabel("Options pour \(game.title)")
        }
    }
}

struct QuickGameView: View {
    let game: Game
    let transition: Namespace.ID
    let reduceMotion: Bool
    let onClose: () -> Void
    let onPlay: () -> Void
    let onDetails: () -> Void

    var body: some View {
        ZStack {
            AveluneTheme.background.opacity(0.65)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack(alignment: .topTrailing) {
                        LibraryArtwork(paths: game.heroCandidates)
                            .frame(height: 240)

                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.headline)
                                .frame(width: 44, height: 44)
                        }
                        .background(.regularMaterial, in: Circle())
                        .padding(12)
                        .accessibilityLabel("Fermer l’aperçu")
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Text(game.title)
                            .font(.system(.largeTitle, design: .serif, weight: .bold))
                            .foregroundStyle(AveluneTheme.text)

                        if let description = game.description, !description.isEmpty {
                            Text(description)
                                .font(.body)
                                .foregroundStyle(AveluneTheme.muted)
                                .lineLimit(4)
                        }

                        if let lastPlayedAt = game.lastPlayedAt {
                            Label("Dernière partie : \(lastPlayedAt.formatted(date: .abbreviated, time: .omitted))", systemImage: "clock")
                                .font(.subheadline)
                                .foregroundStyle(AveluneTheme.muted)
                        }

                        HStack(spacing: 10) {
                            Button(action: onPlay) {
                                Label(game.canContinue ? "Reprendre" : "Jouer", systemImage: "play.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .accessibilityIdentifier("quick-view-play")

                            Button(action: onDetails) {
                                Text("Voir la fiche")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                        .controlSize(.large)
                    }
                    .padding(22)
                }
                .background {
                    if reduceMotion {
                        RoundedRectangle(cornerRadius: 28).fill(AveluneTheme.surface)
                    } else {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(AveluneTheme.surface)
                            .matchedGeometryEffect(id: game.id, in: transition, isSource: false)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(AveluneTheme.border))
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            .frame(maxHeight: 620)
        }
        .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.96)))
    }
}
