import 'package:flutter/widgets.dart';

import 'package:avelune_studio/l10n/app_localizations.dart';

const studioFallbackLocale = Locale('fr');

Locale? studioLocaleFor(String? languageCode) =>
    languageCode == null ? null : resolveStudioLocale(Locale(languageCode));

Locale resolveStudioLocale(Locale? requested) =>
    AppLocalizations.supportedLocales
        .where((locale) => locale.languageCode == requested?.languageCode)
        .firstOrNull ??
    studioFallbackLocale;

extension StudioLocalizationsContext on BuildContext {
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      lookupAppLocalizations(studioFallbackLocale);
}
