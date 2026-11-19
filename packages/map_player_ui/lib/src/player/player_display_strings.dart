import 'package:flutter/widgets.dart';

import '../localization/player_localizations.dart';

final class PlayerDisplayStrings {
  const PlayerDisplayStrings._(this._strings);

  factory PlayerDisplayStrings.of(BuildContext context) =>
      PlayerDisplayStrings._(context.playerL10n);

  final PokeMapPlayerLocalizations _strings;

  String get title => _strings.displayTitle;
  String get mode => _strings.displayMode;
  String get windowed => _strings.displayWindowed;
  String get fullscreen => _strings.displayFullscreen;
  String get windowSize => _strings.displayWindowSize;
  String get compact => _strings.displayCompact;
  String get balanced => _strings.displayBalanced;
  String get spacious => _strings.displaySpacious;
  String get unsupported => _strings.displayUnsupported;
  String get applyFailed => _strings.displayApplyFailed;
}
