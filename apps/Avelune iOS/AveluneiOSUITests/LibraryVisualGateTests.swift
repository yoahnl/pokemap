import XCTest

final class LibraryVisualGateTests: XCTestCase {
    func testLibraryHeaderCollapsesAndExpands() throws {
        let app = XCUIApplication()
        app.launch()

        guard app.otherElements["featured-page-count"].waitForExistence(timeout: 20) else {
            throw XCTSkip("Installer au moins deux jeux pour vérifier le défilement de la bibliothèque.")
        }

        let navigationBar = app.navigationBars["Bibliothèque"]
        let library = app.scrollViews["library-scroll"]
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 5))
        XCTAssertTrue(library.exists)

        let expandedHeight = navigationBar.frame.height
        library.swipeUp()
        let collapse = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in navigationBar.frame.height < expandedHeight - 8 },
            object: nil
        )
        XCTAssertEqual(XCTWaiter.wait(for: [collapse], timeout: 5), .completed)

        library.swipeDown()
        let expand = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in navigationBar.frame.height > expandedHeight - 10 },
            object: nil
        )
        XCTAssertEqual(XCTWaiter.wait(for: [expand], timeout: 5), .completed)
    }

    func testCarouselSwipesBetweenGames() throws {
        let app = XCUIApplication()
        app.launch()

        let page = app.otherElements["featured-page-count"]
        guard page.waitForExistence(timeout: 20) else {
            throw XCTSkip("Installer au moins deux jeux pour vérifier le carrousel.")
        }

        XCTAssertEqual(page.value as? String, "1")
        attachScreenshot(of: app, name: "carrousel-page-1")
        app.scrollViews["featured-carousel"].swipeLeft()
        XCTAssertEqual(page.value as? String, "2")
        attachScreenshot(of: app, name: "carrousel-page-2")
    }

    func testInstalledGameDetailAndQuickViewClose() throws {
        let app = XCUIApplication()
        app.launch()

        let details = app.buttons["Détails"].firstMatch
        guard details.waitForExistence(timeout: 20) else {
            throw XCTSkip("Installer un jeu réel pour vérifier la fiche et l’aperçu.")
        }

        details.tap()
        XCTAssertTrue(app.staticTexts["Informations"].waitForExistence(timeout: 5))
        attachScreenshot(of: app, name: "fiche-jeu")

        app.buttons["Retour à la bibliothèque"].tap()
        findCover(in: app).press(forDuration: 1.2)
        XCTAssertTrue(app.buttons["Voir la fiche"].waitForExistence(timeout: 5))
        attachScreenshot(of: app, name: "apercu-rapide")
        app.buttons["Fermer l’aperçu"].tap()
    }

    func testQuickViewOpensDetail() throws {
        let app = XCUIApplication()
        app.launch()
        guard app.buttons["Détails"].firstMatch.waitForExistence(timeout: 20) else {
            throw XCTSkip("Installer un jeu réel pour vérifier la fiche.")
        }

        findCover(in: app).press(forDuration: 1.2)
        let showDetail = app.buttons["Voir la fiche"]
        XCTAssertTrue(showDetail.waitForExistence(timeout: 5))
        showDetail.tap()
        XCTAssertTrue(app.staticTexts["Informations"].waitForExistence(timeout: 5))
    }

    func testQuickViewLaunchesFlutter() throws {
        let app = XCUIApplication()
        app.launch()
        guard app.buttons["Détails"].firstMatch.waitForExistence(timeout: 20) else {
            throw XCTSkip("Installer un jeu réel pour vérifier le lancement.")
        }

        findCover(in: app).press(forDuration: 1.2)
        let play = app.buttons["quick-view-play"]
        XCTAssertTrue(play.waitForExistence(timeout: 5))
        play.tap()
        XCTAssertFalse(app.statusBars.firstMatch.exists)
        XCTAssertFalse(app.buttons["Fermer"].exists)
        attachScreenshot(of: app, name: "handoff-flutter")
    }

    private func findCover(in app: XCUIApplication) -> XCUIElement {
        app.swipeUp()
        let cover = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "voir la fiche")
        ).firstMatch
        XCTAssertTrue(cover.waitForExistence(timeout: 5))
        return cover
    }

    private func attachScreenshot(of app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
