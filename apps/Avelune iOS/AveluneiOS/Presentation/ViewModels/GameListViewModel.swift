import Foundation
import SwiftUI
import OSLog

enum InstallationStage: String, Identifiable {
    case preparing
    case installing
    case finishing

    var id: String { rawValue }
}

enum LibraryLoadState {
    case loading
    case loaded
    case failed
}

@MainActor
final class GameListViewModel: ObservableObject {
    @Published private(set) var games: [Game] = []
    @Published private(set) var libraryState: LibraryLoadState = .loading
    @Published private(set) var libraryLoadError: String?
    @Published private(set) var isBusy = false
    @Published private(set) var installationStage: InstallationStage?
    @Published private(set) var installationName: String?
    @Published var errorMessage: String?

    private let loadLibraryUseCase: LoadLibraryUseCase
    private let installGameUseCase: InstallGameUseCase
    private let importLogger = Logger(subsystem: "com.yoahnl.avelune.player", category: "GameImport")

    init(loadLibraryUseCase: LoadLibraryUseCase, installGameUseCase: InstallGameUseCase) {
        self.loadLibraryUseCase = loadLibraryUseCase
        self.installGameUseCase = installGameUseCase
    }

    func refresh() async {
        let isInitialLoad = libraryState != .loaded
        if isInitialLoad {
            libraryState = .loading
            libraryLoadError = nil
        }

        do {
            games = try await loadLibraryUseCase.execute()
            libraryState = .loaded
            libraryLoadError = nil
        } catch {
            if isInitialLoad {
                libraryLoadError = error.localizedDescription
                libraryState = .failed
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }

    func install(from url: URL) async {
        importLogger.notice("Starting game package import")
        isBusy = true
        installationName = url.deletingPathExtension().lastPathComponent
        installationStage = .preparing
        defer {
            installationStage = nil
            installationName = nil
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
            libraryState = .loaded
            libraryLoadError = nil
            importLogger.notice("Game package import completed")
        } catch {
            importLogger.error("Game package import failed: \(error.localizedDescription, privacy: .private)")
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
