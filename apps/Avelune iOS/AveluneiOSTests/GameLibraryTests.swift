import XCTest
@testable import AveluneiOS

@MainActor
final class GameLibraryTests: XCTestCase {
    func testLibraryStartsLoadingBeforeTheFirstResponse() {
        let useCase = LibraryUseCaseStub()
        let viewModel = GameListViewModel(loadLibraryUseCase: useCase, installGameUseCase: useCase)

        XCTAssertEqual(viewModel.libraryState, .loading)
        XCTAssertTrue(viewModel.games.isEmpty)
    }

    func testSuccessfulLoadRevealsTheRealLibraryState() async {
        let useCase = LibraryUseCaseStub()
        let viewModel = GameListViewModel(loadLibraryUseCase: useCase, installGameUseCase: useCase)
        useCase.result = .success([Game(payload: ["gameId": "train", "title": "Le train de 17h42"])!])

        await viewModel.refresh()

        XCTAssertEqual(viewModel.libraryState, .loaded)
        XCTAssertEqual(viewModel.games.map(\.id), ["train"])

        useCase.result = .success([])
        await viewModel.refresh()

        XCTAssertEqual(viewModel.libraryState, .loaded)
        XCTAssertTrue(viewModel.games.isEmpty)
    }

    func testFailedFirstLoadCanRetryWithoutShowingAnEmptyLibrary() async {
        let useCase = LibraryUseCaseStub()
        let viewModel = GameListViewModel(loadLibraryUseCase: useCase, installGameUseCase: useCase)
        useCase.result = .failure(LibraryTestError.unavailable)

        await viewModel.refresh()

        XCTAssertEqual(viewModel.libraryState, .failed)
        XCTAssertTrue(viewModel.games.isEmpty)

        useCase.result = .success([Game(payload: ["gameId": "train", "title": "Le train de 17h42"])!])
        await viewModel.refresh()

        XCTAssertEqual(viewModel.libraryState, .loaded)
        XCTAssertEqual(viewModel.games.map(\.id), ["train"])
    }

    func testArtworkFallbacksPreserveOlderPackages() {
        let game = Game(payload: ["gameId": "old", "title": "Ancien jeu", "iconPath": "/icon.png"])

        XCTAssertEqual(game?.coverCandidates, ["/icon.png"])
        XCTAssertEqual(game?.heroCandidates, ["/icon.png"])
        XCTAssertEqual(game?.supportedLocales, ["fr"])
    }

    func testCoverAndHeroKeepTheirOwnPriority() {
        let game = Game(payload: [
            "gameId": "new",
            "title": "Nouveau jeu",
            "coverPath": "/cover.png",
            "heroPath": "/hero.png",
            "iconPath": "/icon.png",
            "supportedLocales": ["fr", "en"]
        ])

        XCTAssertEqual(game?.coverCandidates, ["/cover.png", "/hero.png", "/icon.png"])
        XCTAssertEqual(game?.heroCandidates, ["/hero.png", "/cover.png", "/icon.png"])
        XCTAssertEqual(game?.supportedLocales, ["fr", "en"])
    }

    func testMissingArtworkFallsBackToNextReadableFile() async throws {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".png")
        defer { try? FileManager.default.removeItem(at: path) }

        let image = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
        try XCTUnwrap(image.pngData()).write(to: path)

        let loaded = await LibraryArtworkCache.shared.image(
            for: ["/missing-image.png", path.path],
            maxPixelSize: 100
        )
        XCTAssertNotNil(loaded)

        let missing = await LibraryArtworkCache.shared.image(
            for: ["/missing-image.png"],
            maxPixelSize: 100
        )
        XCTAssertNil(missing)
    }

    func testFeaturedGamesPreferLatestPlayedWithoutChangingOtherOrder() {
        let first = Game(payload: ["gameId": "first", "title": "Premier"])
        let second = Game(payload: [
            "gameId": "second",
            "title": "Deuxième",
            "lastPlayedAt": "2026-09-25T12:00:00Z"
        ])
        let third = Game(payload: [
            "gameId": "third",
            "title": "Troisième",
            "lastPlayedAt": "2026-09-24T12:00:00Z"
        ])
        let games = [first, second, third].compactMap { $0 }

        XCTAssertEqual(Game.featuredOrder([]).count, 0)
        XCTAssertEqual(Game.featuredOrder([games[0]]).map(\.id), ["first"])
        XCTAssertEqual(Game.featuredOrder(games).map(\.id), ["second", "first", "third"])
    }
}

private enum LibraryTestError: Error {
    case unavailable
}

@MainActor
private final class LibraryUseCaseStub: LoadLibraryUseCase, InstallGameUseCase {
    var result: Result<[Game], Error> = .success([])

    func execute() async throws -> [Game] {
        try result.get()
    }

    func install(packagePath: String) async throws -> Game {
        throw LibraryTestError.unavailable
    }

    func uninstall(_ game: Game) async throws -> [Game] {
        throw LibraryTestError.unavailable
    }
}
