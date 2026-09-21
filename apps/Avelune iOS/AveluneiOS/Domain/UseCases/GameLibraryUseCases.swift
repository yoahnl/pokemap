import Foundation

protocol LoadLibraryUseCase {
    func execute() async throws -> [Game]
}

protocol InstallGameUseCase {
    func install(packagePath: String) async throws -> Game
    func uninstall(_ game: Game) async throws -> [Game]
}

protocol PlayGameUseCase {
    func start(_ game: Game) async throws
    func stop() async throws
}

@MainActor
final class DefaultGameLibraryUseCases: LoadLibraryUseCase, InstallGameUseCase, PlayGameUseCase {
    private let repository: GameRepository

    init(repository: GameRepository) {
        self.repository = repository
    }

    func execute() async throws -> [Game] {
        try await repository.installedGames()
    }

    func install(packagePath: String) async throws -> Game {
        try await repository.install(packagePath: packagePath)
    }

    func uninstall(_ game: Game) async throws -> [Game] {
        try await repository.uninstall(game)
    }

    func start(_ game: Game) async throws {
        try await repository.play(game)
    }

    func stop() async throws {
        try await repository.stop()
    }
}
