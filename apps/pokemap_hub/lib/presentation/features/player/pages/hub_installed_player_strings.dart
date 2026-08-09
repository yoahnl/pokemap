import 'package:flutter/widgets.dart';

final class HubInstalledPlayerStrings {
  const HubInstalledPlayerStrings._(this._languageCode);

  factory HubInstalledPlayerStrings.of(BuildContext context) =>
      HubInstalledPlayerStrings.forLocale(
        Localizations.localeOf(context).languageCode,
      );

  factory HubInstalledPlayerStrings.forLocale(String locale) =>
      HubInstalledPlayerStrings._(
        locale.trim().split(RegExp('[-_]')).first.toLowerCase(),
      );

  final String _languageCode;

  bool get _isFrench => _languageCode == 'fr';

  String get defaultProfile => _isFrench ? 'Joueur' : 'Player';
}
