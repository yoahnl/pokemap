import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Resolves the generated shell translations without forcing legacy widget
/// harnesses to install localization delegates immediately.
///
/// French is the deterministic fallback because it is the existing product
/// language. Child-route and authored asset labels remain outside NSC-12.
extension PokeMapLocalizationsContext on BuildContext {
  AppLocalizations get pokeMapL10n =>
      AppLocalizations.of(this) ?? lookupAppLocalizations(const Locale('fr'));
}
