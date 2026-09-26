import Foundation

struct Game: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String?
    let author: String
    let publisher: String?
    let version: String?
    let defaultLocale: String
    let supportedLocales: [String]
    let accentColor: String?
    let iconPath: String?
    let coverPath: String?
    let heroPath: String?
    let canContinue: Bool
    let lastPlayedAt: Date?
    let playTimeSeconds: Int

    var artworkPath: String? { coverPath ?? heroPath ?? iconPath }

    var coverCandidates: [String] { [coverPath, heroPath, iconPath].compactMap { $0 }.uniquePaths }
    var heroCandidates: [String] { [heroPath, coverPath, iconPath].compactMap { $0 }.uniquePaths }

    static func featuredOrder(_ games: [Game]) -> [Game] {
        guard let mostRecent = games.compactMap({ game in
            game.lastPlayedAt.map { (game, $0) }
        }).max(by: { $0.1 < $1.1 })?.0 else { return games }

        return [mostRecent] + games.filter { $0.id != mostRecent.id }
    }

    static func == (lhs: Game, rhs: Game) -> Bool { lhs.id == rhs.id }
}

extension Game {
    init?(payload: [String: Any]) {
        guard let id = payload["gameId"] as? String,
              let title = payload["title"] as? String else { return nil }

        self.id = id
        self.title = title
        description = payload["description"] as? String
        author = payload["author"] as? String ?? ""
        publisher = payload["publisher"] as? String
        version = payload["version"] as? String
        defaultLocale = payload["defaultLocale"] as? String ?? "fr"
        supportedLocales = payload["supportedLocales"] as? [String] ?? [defaultLocale]
        accentColor = payload["accentColor"] as? String
        iconPath = payload["iconPath"] as? String
        coverPath = payload["coverPath"] as? String
        heroPath = payload["heroPath"] as? String
        canContinue = payload["canContinue"] as? Bool ?? false
        playTimeSeconds = payload["playTimeSeconds"] as? Int ?? 0

        if let raw = payload["lastPlayedAt"] as? String {
            lastPlayedAt = ISO8601DateFormatter().date(from: raw)
        } else {
            lastPlayedAt = nil
        }
    }
}

private extension Array where Element == String {
    var uniquePaths: [String] {
        reduce(into: [String]()) { paths, path in
            if !path.isEmpty && !paths.contains(path) { paths.append(path) }
        }
    }
}
