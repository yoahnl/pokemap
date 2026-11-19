import Foundation
import Observation

enum AppLanguage: String, Hashable {
    case system
    case french = "fr"
    case english = "en"

    fileprivate static let explicitChoices: [Self] = [.french, .english]
}

struct LanguagePreferences: Equatable {
    let appLanguage: AppLanguage
    let appLocale: Locale
    let supportedAppLanguages: [AppLanguage]

    init?(payload: Any?) {
        guard let payload = payload as? [String: Any],
              let choiceTag = payload["appLanguage"] as? String,
              let choice = AppLanguage(rawValue: choiceTag),
              let localeTag = payload["appLocale"] as? String,
              let effectiveLanguage = AppLanguage(rawValue: localeTag),
              let supportedTags = payload["supportedAppLanguages"] as? [String] else { return nil }

        let supported = supportedTags.compactMap(AppLanguage.init(rawValue:))
        guard supported.count == supportedTags.count,
              Set(supported).count == supported.count,
              supported.allSatisfy(AppLanguage.explicitChoices.contains),
              supported.contains(effectiveLanguage),
              choice == .system || choice == effectiveLanguage else { return nil }

        appLanguage = choice
        appLocale = Locale(identifier: localeTag)
        supportedAppLanguages = supported
    }
}

@MainActor
@Observable
final class AppLanguageSettings {
    private(set) var confirmed: LanguagePreferences?
    private(set) var isSaving = false
    private(set) var readFailed = false

    private let initialLocale: Locale
    private let read: () async throws -> LanguagePreferences
    private let write: (AppLanguage) async throws -> LanguagePreferences
    private var isRuntimeReady = false
    private var revision = 0

    var locale: Locale { confirmed?.appLocale ?? initialLocale }

    init(read: @escaping () async throws -> LanguagePreferences,
         write: @escaping (AppLanguage) async throws -> LanguagePreferences) {
        let systemLanguage = Locale.preferredLanguages.lazy
            .compactMap { Locale(identifier: $0).language.languageCode?.identifier }
            .compactMap(AppLanguage.init(rawValue:))
            .first(where: AppLanguage.explicitChoices.contains) ?? .english
        initialLocale = Locale(identifier: systemLanguage.rawValue)
        self.read = read
        self.write = write
    }

    func runtimeReady() async {
        isRuntimeReady = true
        await refresh()
    }

    func refresh() async {
        guard isRuntimeReady else { return }
        revision += 1
        let requestRevision = revision
        readFailed = false

        do {
            let preferences = try await read()
            if revision == requestRevision {
                receive(preferences)
            }
        } catch {
            if revision == requestRevision, confirmed == nil {
                readFailed = true
            }
        }
    }

    func receive(_ preferences: LanguagePreferences) {
        guard preferences != confirmed else { return }
        revision += 1
        confirmed = preferences
        readFailed = false
    }

    func select(_ choice: AppLanguage) async -> Bool {
        guard let confirmed,
              choice != confirmed.appLanguage,
              choice == .system || confirmed.supportedAppLanguages.contains(choice),
              !isSaving else { return true }

        isSaving = true
        defer { isSaving = false }
        revision += 1

        do {
            let preferences = try await write(choice)
            guard preferences.appLanguage == choice else { return false }
            if self.confirmed?.appLanguage != choice {
                receive(preferences)
            }
            return true
        } catch {
            return false
        }
    }
}

extension LocalizedStringResource {
    func localized(for locale: Locale) -> String {
        var resource = self
        resource.locale = locale
        return String(localized: resource)
    }
}
