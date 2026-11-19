import 'package:flutter/widgets.dart';

import '../localization/player_localizations.dart';

final class PlayerStartupStrings {
  const PlayerStartupStrings._(this._strings);

  factory PlayerStartupStrings.of(BuildContext context) =>
      PlayerStartupStrings._(context.playerL10n);

  final PokeMapPlayerLocalizations _strings;

  String get pressStart => _strings.startupPressStart;
  String get replayIntro => _strings.startupReplayIntro;
  String get replaceSaveTitle => _strings.startupReplaceSaveTitle;
  String get replaceSaveBody => _strings.startupReplaceSaveBody;
  String get cancel => _strings.cancel;
  String get begin => _strings.startupBegin;
  String get startupUnavailable => _strings.startupStartupUnavailable;
  String get retry => _strings.retry;
  String get preparing => _strings.startupPreparing;
}
