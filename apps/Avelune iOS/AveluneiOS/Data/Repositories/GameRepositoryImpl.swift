import Foundation

@MainActor
final class GameRepositoryImpl: GameRepository {
    private let dataSource: FlutterGameDataSource

    init(dataSource: FlutterGameDataSource) {
        self.dataSource = dataSource
    }

    func installedGames() async throws -> [Game] {
        try await dataSource.listGames()
    }

    func install(packagePath: String, onProgress: @escaping (InstallProgress) -> Void) async throws -> Game {
        try await dataSource.install(packagePath: packagePath, onProgress: onProgress)
    }

    func uninstall(_ game: Game) async throws -> [Game] {
        try await dataSource.uninstall(gameId: game.id)
    }

    func play(_ game: Game) async throws {
        try await dataSource.play(gameId: game.id)
    }

    func stop() async throws {
        try await dataSource.stop()
    }
}
