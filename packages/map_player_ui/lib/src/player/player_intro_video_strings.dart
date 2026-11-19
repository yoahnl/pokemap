import 'package:flutter/widgets.dart';

import '../localization/player_localizations.dart';

final class PlayerIntroVideoStrings {
  const PlayerIntroVideoStrings._(this._strings);

  factory PlayerIntroVideoStrings.of(BuildContext context) =>
      PlayerIntroVideoStrings._(context.playerL10n);

  final PokeMapPlayerLocalizations _strings;

  String get skip => _strings.introVideoSkip;
  String get replay => _strings.introVideoReplay;
  String get continueAction => _strings.continueGame;
  String get unavailable => _strings.introVideoUnavailable;
  String get reducedMotionSkipped => _strings.introVideoReducedMotionSkipped;
}
