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
    @Published private(set) var libraryLoadError: LocalizedStringResource?
    @Published private(set) var isBusy = false
    @Published private(set) var installationStage: InstallationStage?
    @Published private(set) var installationName: String?
    @Published private(set) var installationProgress: Double?
    @Published private(set) var installationDetail: LocalizedStringResource?
    @Published var errorMessage: LocalizedStringResource?

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
            let detail = (error as? RuntimeChannelError)?.userFacingMessage
            if isInitialLoad {
                libraryLoadError = detail
                libraryState = .failed
            } else {
                errorMessage = detail ?? "Impossible d’actualiser la bibliothèque."
            }
        }
    }

    func install(from url: URL) async {
        importLogger.notice("Starting game package import")
        isBusy = true
        installationName = url.deletingPathExtension().lastPathComponent
        installationStage = .preparing
        installationProgress = nil
        installationDetail = nil
        defer {
            installationStage = nil
            installationName = nil
            installationProgress = nil
            installationDetail = nil
            isBusy = false
        }

        do {
            guard let packagePath = await Task.detached(priority: .userInitiated, operation: {
                Self.copyToLocal(url: url)
            }).value else {
                importLogger.error("Game package import failed: unable to copy the selected file")
                errorMessage = "Impossible de copier le fichier .avelunegame."
                return
            }
            defer { try? FileManager.default.removeItem(atPath: packagePath) }

            installationStage = .installing
            _ = try await installGameUseCase.install(packagePath: packagePath) { [weak self] progress in
                self?.apply(progress)
            }
            installationStage = .finishing
            games = try await loadLibraryUseCase.execute()
            libraryState = .loaded
            libraryLoadError = nil
            importLogger.notice("Game package import completed")
        } catch {
            importLogger.error("Game package import failed: \(error.localizedDescription, privacy: .private)")
            errorMessage = (error as? RuntimeChannelError)?.userFacingMessage ?? "Impossible d’installer ce jeu."
        }
    }

    private func apply(_ progress: InstallProgress) {
        installationProgress = progress.fraction
        installationDetail = progress.detail
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
            errorMessage = (error as? RuntimeChannelError)?.userFacingMessage ?? "Impossible de supprimer ce jeu."
        }
    }
}
