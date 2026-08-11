import 'package:flutter/widgets.dart';

final class PlayerIntroVideoStrings {
  const PlayerIntroVideoStrings._(this._languageCode);

  factory PlayerIntroVideoStrings.of(BuildContext context) =>
      PlayerIntroVideoStrings._(
        Localizations.localeOf(context).languageCode,
      );

  final String _languageCode;

  bool get _isFrench => _languageCode == 'fr';

  String get skip => _isFrench ? 'Passer' : 'Skip';
  String get replay => _isFrench ? 'Rejouer' : 'Replay';
  String get continueAction => _isFrench ? 'Continuer' : 'Continue';
  String get unavailable => _isFrench
      ? 'La vidéo ne peut pas être lue.'
      : 'Video playback is unavailable.';
  String get reducedMotionSkipped => _isFrench
      ? 'Intro ignorée avec les animations réduites'
      : 'Intro skipped with reduced motion';
}
