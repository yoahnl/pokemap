import XCTest
@testable import AveluneiOS

@MainActor
final class LanguagePreferencesTests: XCTestCase {
    func testDecodesConfirmedSystemAndExplicitChoices() throws {
        let inherited = try XCTUnwrap(LanguagePreferences(payload: payload("system", "fr")))
        XCTAssertEqual(inherited.appLanguage, .system)
        XCTAssertEqual(inherited.appLocale.identifier, "fr")
        XCTAssertEqual(inherited.supportedAppLanguages, [.french, .english])

        let explicit = try XCTUnwrap(LanguagePreferences(payload: payload("en", "en", ["en", "fr"])))
        XCTAssertEqual(explicit.appLanguage, .english)
        XCTAssertEqual(explicit.appLocale.identifier, "en")
        XCTAssertEqual(explicit.supportedAppLanguages, [.english, .french])
    }

    func testRejectsInvalidPayloads() {
        XCTAssertNil(LanguagePreferences(payload: nil))
        XCTAssertNil(LanguagePreferences(payload: ["appLanguage": "system"]))
        XCTAssertNil(LanguagePreferences(payload: payload("de", "fr")))
        XCTAssertNil(LanguagePreferences(payload: payload("system", "de")))
        XCTAssertNil(LanguagePreferences(payload: payload("fr", "en")))
        XCTAssertNil(LanguagePreferences(payload: payload("system", "fr", ["en"])))
        XCTAssertNil(LanguagePreferences(payload: payload("system", "fr", ["fr", "system"])))
        XCTAssertNil(LanguagePreferences(payload: payload("system", "fr", ["fr", "fr"])))
    }

    func testReadsWhenRuntimeIsReadyAndRefreshesOnReturn() async throws {
        let frenchSystem = try XCTUnwrap(LanguagePreferences(payload: payload("system", "fr")))
        let englishSystem = try XCTUnwrap(LanguagePreferences(payload: payload("system", "en")))
        var confirmed = frenchSystem
        var reads = 0
        let settings = AppLanguageSettings(read: {
            reads += 1
            return confirmed
        }, write: { _ in throw BridgeFailure.unavailable })

        await settings.refresh()
        XCTAssertEqual(reads, 0)
        XCTAssertNil(settings.confirmed)

        await settings.runtimeReady()
        XCTAssertEqual(reads, 1)
        XCTAssertEqual(settings.confirmed, frenchSystem)

        confirmed = englishSystem
        await settings.refresh()
        XCTAssertEqual(reads, 2)
        XCTAssertEqual(settings.confirmed, englishSystem)
        XCTAssertEqual(settings.locale.identifier, "en")
    }

    func testDisplaysOnlyAcknowledgedChangesAndReturnsToSystem() async throws {
        let frenchSystem = try XCTUnwrap(LanguagePreferences(payload: payload("system", "fr")))
        let english = try XCTUnwrap(LanguagePreferences(payload: payload("en", "en")))
        let writeStarted = expectation(description: "Language write started")
        var pendingWrite: CheckedContinuation<LanguagePreferences, Error>?
        var choices: [AppLanguage] = []
        let settings = AppLanguageSettings(read: { frenchSystem }, write: { choice in
            choices.append(choice)
            if choice == .system { return frenchSystem }
            return try await withCheckedThrowingContinuation { continuation in
                pendingWrite = continuation
                writeStarted.fulfill()
            }
        })
        await settings.runtimeReady()

        let write = Task { await settings.select(.english) }
        await fulfillment(of: [writeStarted], timeout: 3)
        XCTAssertTrue(settings.isSaving)
        XCTAssertEqual(settings.confirmed, frenchSystem)
        pendingWrite?.resume(returning: english)
        let succeeded = await write.value
        XCTAssertTrue(succeeded)
        XCTAssertFalse(settings.isSaving)
        XCTAssertEqual(settings.confirmed, english)

        let followsPhone = await settings.select(.system)
        XCTAssertTrue(followsPhone)
        XCTAssertEqual(settings.confirmed, frenchSystem)
        XCTAssertEqual(choices, [.english, .system])
    }

    func testFailedPersistenceKeepsThePreviousChoice() async throws {
        let french = try XCTUnwrap(LanguagePreferences(payload: payload("fr", "fr")))
        let settings = AppLanguageSettings(read: { french }, write: { _ in throw BridgeFailure.unavailable })
        await settings.runtimeReady()

        let succeeded = await settings.select(.english)

        XCTAssertFalse(succeeded)
        XCTAssertFalse(settings.isSaving)
        XCTAssertEqual(settings.confirmed, french)
        XCTAssertEqual(settings.locale.identifier, "fr")
    }

    func testFirstReadCanRetryAfterFailure() async throws {
        let french = try XCTUnwrap(LanguagePreferences(payload: payload("fr", "fr")))
        var response: Result<LanguagePreferences, Error> = .failure(BridgeFailure.unavailable)
        let settings = AppLanguageSettings(read: { try response.get() }, write: { _ in throw BridgeFailure.unavailable })

        await settings.runtimeReady()
        XCTAssertTrue(settings.readFailed)
        XCTAssertNil(settings.confirmed)

        response = .success(french)
        await settings.refresh()
        XCTAssertFalse(settings.readFailed)
        XCTAssertEqual(settings.confirmed, french)
    }

    func testLateReadCannotOverwriteANewerNotification() async throws {
        let frenchSystem = try XCTUnwrap(LanguagePreferences(payload: payload("system", "fr")))
        let englishSystem = try XCTUnwrap(LanguagePreferences(payload: payload("system", "en")))
        let readStarted = expectation(description: "Language read started")
        var pendingRead: CheckedContinuation<LanguagePreferences, Error>?
        let settings = AppLanguageSettings(read: {
            try await withCheckedThrowingContinuation { continuation in
                pendingRead = continuation
                readStarted.fulfill()
            }
        }, write: { _ in throw BridgeFailure.unavailable })

        let load = Task { await settings.runtimeReady() }
        await fulfillment(of: [readStarted], timeout: 3)
        settings.receive(englishSystem)
        pendingRead?.resume(returning: frenchSystem)
        await load.value

        XCTAssertEqual(settings.confirmed, englishSystem)
    }

    func testLateAcknowledgmentKeepsTheNewerSystemLocale() async throws {
        let french = try XCTUnwrap(LanguagePreferences(payload: payload("fr", "fr")))
        let frenchSystem = try XCTUnwrap(LanguagePreferences(payload: payload("system", "fr")))
        let englishSystem = try XCTUnwrap(LanguagePreferences(payload: payload("system", "en")))
        let writeStarted = expectation(description: "Language write started")
        var pendingWrite: CheckedContinuation<LanguagePreferences, Error>?
        let settings = AppLanguageSettings(read: { french }, write: { _ in
            try await withCheckedThrowingContinuation { continuation in
                pendingWrite = continuation
                writeStarted.fulfill()
            }
        })
        await settings.runtimeReady()

        let write = Task { await settings.select(.system) }
        await fulfillment(of: [writeStarted], timeout: 3)
        settings.receive(englishSystem)
        pendingWrite?.resume(returning: frenchSystem)
        let succeeded = await write.value

        XCTAssertTrue(succeeded)
        XCTAssertEqual(settings.confirmed, englishSystem)
    }

    private func payload(_ choice: String, _ locale: String, _ supported: [String] = ["fr", "en"]) -> [String: Any] {
        ["appLanguage": choice, "appLocale": locale, "supportedAppLanguages": supported]
    }
}

private enum BridgeFailure: Error {
    case unavailable
}
