import Foundation
import SwiftUI

@MainActor
final class GameListViewModel: ObservableObject {
    @Published private(set) var games: [Game] = []
    @Published private(set) var isBusy = false
    @Published var errorMessage: String?

    private let loadLibraryUseCase: LoadLibraryUseCase
    private let installGameUseCase: InstallGameUseCase

    init(loadLibraryUseCase: LoadLibraryUseCase, installGameUseCase: InstallGameUseCase) {
        self.loadLibraryUseCase = loadLibraryUseCase
        self.installGameUseCase = installGameUseCase
    }

    func refresh() async {
        do {
            games = try await loadLibraryUseCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func install(packagePath: String) async {
        isBusy = true
        defer { isBusy = false }

        do {
            _ = try await installGameUseCase.install(packagePath: packagePath)
            games = try await loadLibraryUseCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func uninstall(_ game: Game) async {
        isBusy = true
        defer { isBusy = false }

        do {
            games = try await installGameUseCase.uninstall(game)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
