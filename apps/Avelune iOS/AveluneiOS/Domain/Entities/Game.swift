import Foundation

struct Game: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String?
    let author: String
    let publisher: String?
    let version: String?
    let defaultLocale: String
    let accentColor: String?
    let iconPath: String?
    let coverPath: String?
    let heroPath: String?
    let canContinue: Bool
    let lastPlayedAt: Date?
    let playTimeSeconds: Int

    /// Cover first, then hero, then icon: the order the Flutter library uses.
    var artworkPath: String? { coverPath ?? heroPath ?? iconPath }

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
