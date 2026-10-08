import XCTest

final class SpatialGameplayImportTests: XCTestCase {
    private var application: XCUIApplication?

    override func setUpWithError() throws {
        continueAfterFailure = false
        executionTimeAllowance = 240
    }

    override func tearDownWithError() throws {
        if let app = application {
            let tree = XCTAttachment(string: app.debugDescription)
            tree.name = "spatial-ios-final-accessibility-tree"
            tree.lifetime = .keepAlways
            add(tree)
            attachScreenshot(app, name: "spatial-ios-final")
        }
    }

    func testImportPackageAndPlaySpatialNewGameWithTouch() throws {
        let environment = ProcessInfo.processInfo.environment
        guard let packagePath = environment["ENV_AVELUNE_UI_GAME_PACKAGE_PATH"] else {
            throw XCTSkip("TEST_RUNNER_ENV_AVELUNE_UI_GAME_PACKAGE_PATH absent du lancement Xcode ; clés Valbois présentes : \(environment.keys.filter { $0.contains("AVELUNE_UI") }.sorted()).")
        }
        guard packagePath.hasPrefix("/"),
              URL(fileURLWithPath: packagePath).pathExtension == "avelunegame" else {
            throw XCTSkip("AVELUNE_UI_GAME_PACKAGE_PATH doit être un chemin absolu vers un paquet .avelunegame : \(packagePath).")
        }
        guard FileManager.default.fileExists(atPath: packagePath) else {
            throw XCTSkip("Le runner ne peut pas lire le vrai paquet du fournisseur Documents : \(packagePath).")
        }
        let packageName = URL(fileURLWithPath: packagePath).deletingPathExtension().lastPathComponent
        guard let simulatorDataPath = environment["ENV_AVELUNE_UI_SIMULATOR_DATA_ROOT"], simulatorDataPath.hasPrefix("/") else {
            throw XCTSkip("TEST_RUNNER_ENV_AVELUNE_UI_SIMULATOR_DATA_ROOT absent du lancement Xcode pour la lecture seule des sauvegardes.")
        }
        let simulatorDataRoot = URL(fileURLWithPath: simulatorDataPath, isDirectory: true)
        let gameTitle = environment["ENV_AVELUNE_UI_GAME_TITLE"] ?? "Valbois — Voyage en 3D"
        let app = XCUIApplication()
        application = app
        app.launchArguments = ["-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR"]
        app.launch()

        let importButton = app.buttons["Importer un jeu"].firstMatch
        try require(importButton.waitForExistence(timeout: 30), "Le bouton d’import de la bibliothèque doit apparaître.", app)
        let gameCount = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "^[0-9]+ aventures?$")).firstMatch
        try require(gameCount.waitForExistence(timeout: 45), "La bibliothèque doit terminer son chargement avant le parcours d’import.", app)
        let cover = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", gameTitle, "voir la fiche")
        ).firstMatch
        try removeExistingQACartridge(gameTitle, cover: cover, in: app)
        try require(!cover.exists, "Le jeu QA doit être absent avant le test afin de prouver un nouvel import.", app)
        try require(gameCount.waitForExistence(timeout: 10), "La bibliothèque doit afficher son inventaire avant l’import.", app)
        let previousGameCount = gameCount.label
        attachScreenshot(app, name: "spatial-ios-library-before-import")
        importButton.tap()
        try choosePackage(packageName, in: app)

        let importResult = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                cover.exists || app.alerts["Erreur"].exists ||
                    (gameCount.exists && gameCount.label != previousGameCount)
            },
            object: nil
        )
        _ = XCTWaiter.wait(for: [importResult], timeout: 90)
        let library = app.scrollViews["library-scroll"].firstMatch
        for _ in 0..<4 {
            if cover.exists && cover.isHittable { break }
            if app.alerts["Erreur"].exists { break }
            library.swipeUp()
        }
        try require(cover.exists, "Le vrai import doit ajouter la fiche du jeu \(gameTitle).", app)
        attachScreenshot(app, name: "spatial-ios-library-imported")
        if !cover.isHittable {
            app.swipeUp()
        }
        try require(cover.isHittable, "La fiche du jeu importé doit être accessible.", app)
        cover.tap()

        let play = button(["Jouer", "Reprendre"], in: app)
        try require(play.waitForExistence(timeout: 10), "La fiche doit proposer le lancement du jeu.", app)
        play.tap()
        let titlePrompt = app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS %@ OR identifier == %@", "Appuyer sur Start", "player-title-prompt-hit-area")
        ).firstMatch
        try require(titlePrompt.waitForExistence(timeout: 45) && titlePrompt.isHittable, "Le vrai titre Flutter doit afficher son contrôle de démarrage.", app)
        attachScreenshot(app, name: "spatial-ios-title-prompt")
        titlePrompt.tap()
        let newGame = button(["Nouveau jeu", "New game"], in: app)
        try require(newGame.waitForExistence(timeout: 45), "Le titre Flutter doit proposer une nouvelle partie.", app)
        attachScreenshot(app, name: "spatial-ios-flutter-title")
        newGame.tap()
        let replaceSave = app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS %@", "Cette sauvegarde existe déjà")
        ).firstMatch
        if replaceSave.waitForExistence(timeout: 5) {
            let confirmReplacement = button(["Oui", "Yes"], in: app)
            try require(confirmReplacement.exists && confirmReplacement.isHittable, "La nouvelle partie doit confirmer le remplacement de la sauvegarde QA dans la vraie UI.", app)
            confirmReplacement.tap()
        }

        let introduction = app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS %@", "Bienvenue à Valbois")
        ).firstMatch
        try require(introduction.waitForExistence(timeout: 20), "La vraie scène d’introduction doit être visible.", app)
        attachScreenshot(app, name: "spatial-ios-introduction")
        let menu = app.buttons["Menu"].firstMatch
        for _ in 0..<6 {
            if menu.exists && menu.isHittable { break }
            let next = app.descendants(matching: .any).matching(
                NSPredicate(format: "label IN %@ OR identifier == %@", ["Suite", "Continuer", "Continue"], "dialogue-tap-zone")
            ).firstMatch
            try require(next.waitForExistence(timeout: 5), "L’introduction doit proposer son contrôle de continuation.", app)
            next.tap()
            _ = menu.waitForExistence(timeout: 2)
        }
        try require(menu.waitForExistence(timeout: 30) && menu.isHittable, "La partie doit atteindre la surface jouable avec son menu tactile.", app)
        let initialPose = try saveSpatialPose("before-touch", in: app, simulatorDataRoot: simulatorDataRoot)
        attachScreenshot(app, name: "spatial-ios-before-touch")

        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.20, dy: 0.55))
        let right = app.coordinate(withNormalizedOffset: CGVector(dx: 0.38, dy: 0.55))
        start.press(forDuration: 0.12, thenDragTo: right, withVelocity: .slow, thenHoldForDuration: 0.60)
        attachScreenshot(app, name: "spatial-ios-after-touch-right")
        let up = app.coordinate(withNormalizedOffset: CGVector(dx: 0.20, dy: 0.45))
        start.press(forDuration: 0.12, thenDragTo: up, withVelocity: .slow, thenHoldForDuration: 0.60)
        attachScreenshot(app, name: "spatial-ios-after-touch-up")
        Thread.sleep(forTimeInterval: 1.1)
        attachScreenshot(app, name: "spatial-ios-stopped-after-release")
        let movedPose = try saveSpatialPose("after-touch", in: app, simulatorDataRoot: simulatorDataRoot)
        try require(movedPose.mapId == initialPose.mapId && movedPose.x > initialPose.x && movedPose.z < initialPose.z, "Les vraies sauvegardes doivent prouver le déplacement tactile à droite puis vers le haut.", app)
        try require(menu.exists && menu.isHittable, "Le joueur doit rester actif après les gestes tactiles.", app)
        menu.tap()

        let party = app.buttons["pause.party"].firstMatch
        try require(party.waitForExistence(timeout: 10), "Le vrai menu doit proposer l’équipe.", app)
        party.tap()
        let starter = app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS[c] %@ OR label CONTAINS[c] %@", "Bulbizarre", "Bulbasaur")
        ).firstMatch
        try require(starter.waitForExistence(timeout: 10), "L’équipe réelle doit afficher le Bulbizarre initial.", app)
        attachScreenshot(app, name: "spatial-ios-party")

        let back = button(["Retour", "Back"], in: app)
        try require(back.waitForExistence(timeout: 5), "L’équipe doit permettre de revenir au menu.", app)
        back.tap()
        let resume = button(["Reprendre", "Resume"], in: app)
        try require(resume.waitForExistence(timeout: 5), "Le menu doit permettre de reprendre la partie.", app)
        resume.tap()
        try require(menu.waitForExistence(timeout: 10) && menu.isHittable, "La vue jouable doit reprendre après le menu.", app)
        attachScreenshot(app, name: "spatial-ios-resumed")
    }

    private func choosePackage(_ name: String, in app: XCUIApplication) throws {
        let pickerFile = app.cells.matching(
            NSPredicate(format: "label BEGINSWITH[c] %@ OR identifier BEGINSWITH[c] %@", name, name)
        ).firstMatch
        if !pickerFile.waitForExistence(timeout: 4) {
            let browse = button(["Parcourir", "Explorer", "Browse"], in: app)
            if browse.exists && browse.isHittable {
                browse.tap()
            }
            let local = app.descendants(matching: .any).matching(
                NSPredicate(format: "label == %@ OR label == %@", "Sur mon iPhone", "On My iPhone")
            ).firstMatch
            if local.waitForExistence(timeout: 3) && local.isHittable {
                local.tap()
            }
            if !pickerFile.waitForExistence(timeout: 3) {
                let search = app.searchFields.firstMatch
                try require(search.waitForExistence(timeout: 5), "Le sélecteur Documents doit exposer le fichier ou sa recherche.", app)
                search.tap()
                search.typeText(name)
            }
        }
        let pickerTree = XCTAttachment(string: app.debugDescription)
        pickerTree.name = "spatial-ios-document-picker-accessibility-tree"
        pickerTree.lifetime = .keepAlways
        add(pickerTree)
        attachScreenshot(app, name: "spatial-ios-document-picker")
        try require(pickerFile.waitForExistence(timeout: 15) && pickerFile.isHittable, "Le paquet \(name) doit être sélectionnable dans le vrai fournisseur Files.", app)
        pickerFile.tap()
        let open = button(["Ouvrir", "Open"], in: app)
        if open.waitForExistence(timeout: 2) && open.isHittable {
            open.tap()
        }
    }

    private func removeExistingQACartridge(_ title: String, cover: XCUIElement, in app: XCUIApplication) throws {
        let library = app.scrollViews["library-scroll"].firstMatch
        for _ in 0..<3 {
            if cover.exists && cover.isHittable { break }
            library.swipeUp()
        }
        if cover.exists {
            let options = app.buttons["Options pour \(title)"].firstMatch
            try require(options.exists && options.isHittable, "Seules les options de la cartouche QA peuvent être ouvertes pour le nettoyage.", app)
            options.tap()
            let remove = app.buttons["Supprimer le jeu"].firstMatch
            try require(remove.waitForExistence(timeout: 5), "Le nettoyage doit passer par la vraie commande de suppression du jeu.", app)
            remove.tap()
            let removed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in !cover.exists }, object: nil)
            try require(XCTWaiter.wait(for: [removed], timeout: 20) == .completed, "La cartouche QA doit quitter la bibliothèque avant le nouvel import.", app)
            attachScreenshot(app, name: "spatial-ios-qa-cartridge-removed")
        }
        for _ in 0..<3 { library.swipeDown() }
    }

    private func saveSpatialPose(_ name: String, in app: XCUIApplication, simulatorDataRoot: URL) throws -> SpatialSavedPose {
        app.buttons["Menu"].firstMatch.tap()
        let save = app.buttons["pause.save"].firstMatch
        try require(save.waitForExistence(timeout: 10) && save.isHittable, "Le vrai menu doit proposer la sauvegarde.", app)
        save.tap()
        let confirm = button(["Sauvegarder", "Save"], in: app)
        try require(confirm.waitForExistence(timeout: 5) && confirm.isHittable, "La sauvegarde doit demander une confirmation réelle.", app)
        confirm.tap()
        let success = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "Partie sauvegardée")).firstMatch
        try require(success.waitForExistence(timeout: 20), "La vraie sauvegarde doit être confirmée par son reçu.", app)
        attachScreenshot(app, name: "spatial-ios-save-\(name)")

        let containers = simulatorDataRoot.appendingPathComponent("Containers/Data/Application", isDirectory: true)
        let candidates = try FileManager.default.contentsOfDirectory(at: containers, includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey])
        let appContainers = candidates.filter { candidate in
            guard let values = try? candidate.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey]), values.isDirectory == true, values.isSymbolicLink != true,
                  let metadata = try? Data(contentsOf: candidate.appendingPathComponent(".com.apple.mobile_container_manager.metadata.plist")),
                  let dictionary = try? PropertyListSerialization.propertyList(from: metadata, options: [], format: nil) as? [String: Any] else { return false }
            return dictionary["MCMMetadataIdentifier"] as? String == "com.yoahnl.avelune.player"
        }
        try require(appContainers.count == 1, "Le store doit être lu dans l’unique conteneur réel de l’application iOS.", app)
        let saveFile = appContainers[0].appendingPathComponent("Library/Application Support/PokeMap/saves/games.yoahn.valbois/default/slot-1/save.json")
        let data = try Data(contentsOf: saveFile)
        let envelope = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(envelope["gameId"] as? String, "games.yoahn.valbois")
        let state = try XCTUnwrap(envelope["state"] as? [String: Any])
        let spatial = try XCTUnwrap(state["playerSpatialPosition"] as? [String: Any])
        let grid = try XCTUnwrap(state["playerPosition"] as? [String: Any])
        let pose = SpatialSavedPose(
            mapId: try XCTUnwrap(state["currentMapId"] as? String),
            x: try XCTUnwrap(spatial["x"] as? NSNumber).doubleValue,
            z: try XCTUnwrap(spatial["z"] as? NSNumber).doubleValue
        )
        XCTAssertEqual(spatial["schemaVersion"] as? Int, 1)
        XCTAssertEqual(grid["x"] as? Int, Int(floor(pose.x)))
        XCTAssertEqual(grid["y"] as? Int, Int(floor(pose.z)))
        let snapshot = XCTAttachment(data: data, uniformTypeIdentifier: "public.json")
        snapshot.name = "spatial-ios-save-\(name)-readonly-envelope"
        snapshot.lifetime = .keepAlways
        add(snapshot)
        let back = button(["Retour", "Back"], in: app)
        try require(back.waitForExistence(timeout: 5) && back.isHittable, "Le reçu doit permettre de revenir au menu.", app)
        back.tap()
        let resume = app.buttons["pause-frame-return"].firstMatch
        try require(resume.waitForExistence(timeout: 5) && resume.isHittable, "Le menu doit reprendre la partie après sa sauvegarde.", app)
        resume.tap()
        try require(app.buttons["Menu"].firstMatch.waitForExistence(timeout: 10), "La vue jouable doit revenir après la sauvegarde.", app)
        return pose
    }

    private func button(_ labels: [String], in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label IN %@", labels)).firstMatch
    }

    private func require(_ condition: Bool, _ message: String, _ app: XCUIApplication) throws {
        if condition { return }
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = "spatial-ios-failure-accessibility-tree"
        tree.lifetime = .keepAlways
        add(tree)
        attachScreenshot(app, name: "spatial-ios-failure")
        XCTFail(message)
        throw SpatialGateFailure.unexpectedSurface(message)
    }

    private func attachScreenshot(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

private enum SpatialGateFailure: Error {
    case unexpectedSurface(String)
}

private struct SpatialSavedPose {
    let mapId: String
    let x: Double
    let z: Double
}
