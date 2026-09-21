import Flutter
import Foundation
import SwiftUI

@MainActor
final class GamePlayerViewModel: ObservableObject {
    @Published var errorMessage: String?

    private let playGameUseCase: PlayGameUseCase
    private let engineManager: FlutterEngineManager
    private let dataSource: FlutterGameDataSource

    var flutterEngine: FlutterEngine? { engineManager.engine }

    init(
        playGameUseCase: PlayGameUseCase,
        engineManager: FlutterEngineManager,
        dataSource: FlutterGameDataSource
    ) {
        self.playGameUseCase = playGameUseCase
        self.engineManager = engineManager
        self.dataSource = dataSource
    }

    func start(_ game: Game, onExit: @escaping () -> Void) async {
        dataSource.onPlayerExit = onExit
        do {
            try await playGameUseCase.start(game)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stop() async {
        dataSource.onPlayerExit = nil
        try? await playGameUseCase.stop()
    }
}
