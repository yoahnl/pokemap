import SwiftUI

struct GameDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showsFullDescription = false

    let game: Game
    let onPlay: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 12) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .frame(width: 44, height: 44)
                    }
                    .aveluneGlassButton(circular: true)
                    .accessibilityLabel("Retour à la bibliothèque")

                    Image("AveluneMoon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 38, height: 38)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .accessibilityHidden(true)

                    Text("Avelune")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(AveluneTheme.text)
                }
                .padding(.horizontal, 24)

                ZStack(alignment: .bottomLeading) {
                    LibraryArtwork(paths: game.heroCandidates)

                    LinearGradient(
                        colors: [.clear, .black.opacity(0.28), .black.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    Text(game.title)
                        .font(.system(.largeTitle, design: .serif, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(22)
                }
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 18) {
                    Button(action: onPlay) {
                        Label(game.canContinue ? "Reprendre" : "Jouer", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    if let description = game.description, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("À propos de ce jeu")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundStyle(AveluneTheme.text)

                            Text(description)
                                .font(.body)
                                .foregroundStyle(AveluneTheme.muted)
                                .lineLimit(showsFullDescription ? nil : 4)

                            if description.count > 180 {
                                Button(showsFullDescription ? "Voir moins" : "Voir plus") {
                                    showsFullDescription.toggle()
                                }
                                .font(.subheadline.weight(.semibold))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .background(AveluneTheme.surface, in: RoundedRectangle(cornerRadius: 22))
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Informations")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(AveluneTheme.text)

                        if !game.author.isEmpty {
                            information("Créé par", value: game.author, symbol: "person")
                        }
                        if let publisher = game.publisher, !publisher.isEmpty {
                            information("Édité par", value: publisher, symbol: "building.2")
                        }
                        if let version = game.version, !version.isEmpty {
                            information("Version", value: version, symbol: "tag")
                        }
                        if !game.supportedLocales.isEmpty {
                            information(
                                "Langues",
                                value: game.supportedLocales.map {
                                    Locale(identifier: "fr").localizedString(forIdentifier: $0) ?? $0
                                }.joined(separator: ", "),
                                symbol: "globe"
                            )
                        }
                        if let lastPlayedAt = game.lastPlayedAt {
                            information(
                                "Dernière partie",
                                value: lastPlayedAt.formatted(date: .abbreviated, time: .shortened),
                                symbol: "clock"
                            )
                        }
                        if game.playTimeSeconds > 0 {
                            information(
                                "Temps de jeu",
                                value: Duration.seconds(game.playTimeSeconds).formatted(.units(allowed: [.hours, .minutes])),
                                symbol: "hourglass"
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(AveluneTheme.surface, in: RoundedRectangle(cornerRadius: 22))
                }
                .padding(.horizontal, 24)
            }
            .padding(.top, 12)
            .padding(.bottom, 36)
        }
        .scrollIndicators(.hidden)
        .background(AveluneBackground())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func information(_ title: String, value: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .frame(width: 22)
                .foregroundStyle(AveluneTheme.lilac)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(AveluneTheme.muted)
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(AveluneTheme.text)
            }
        }
    }
}
