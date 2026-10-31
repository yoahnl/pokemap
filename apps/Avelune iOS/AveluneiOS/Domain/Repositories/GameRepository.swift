import Foundation

protocol GameRepository {
    func installedGames() async throws -> [Game]
    func install(packagePath: String, onProgress: @escaping (InstallProgress) -> Void) async throws -> Game
    func uninstall(_ game: Game) async throws -> [Game]
    func play(_ game: Game) async throws
    func stop() async throws
}
