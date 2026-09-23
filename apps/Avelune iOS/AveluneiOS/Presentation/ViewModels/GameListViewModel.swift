import Foundation
import SwiftUI

enum InstallationStage: String, Identifiable {
    case preparing
    case installing
    case finishing

    var id: String { rawValue }
}

@MainActor
final class GameListViewModel: ObservableObject {
    @Published private(set) var games: [Game] = []
    @Published private(set) var isBusy = false
    @Published private(set) var installationStage: InstallationStage?
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

    func install(from url: URL) async {
        isBusy = true
        installationStage = .preparing
        defer {
            installationStage = nil
            isBusy = false
        }

        do {
            guard let packagePath = await Task.detached(priority: .userInitiated, operation: {
                Self.copyToLocal(url: url)
            }).value else {
                throw CocoaError(.fileReadUnknown)
            }
            defer { try? FileManager.default.removeItem(atPath: packagePath) }

            installationStage = .installing
            _ = try await installGameUseCase.install(packagePath: packagePath)
            installationStage = .finishing
            games = try await loadLibraryUseCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private nonisolated static func copyToLocal(url: URL) -> String? {
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + "-" + url.lastPathComponent)

        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        do {
            try FileManager.default.copyItem(at: url, to: destination)
            return destination.path
        } catch {
            try? FileManager.default.removeItem(at: destination)
            return nil
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
